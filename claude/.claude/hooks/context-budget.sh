#!/bin/bash
# UserPromptSubmit + PostToolUse hook (sometimeskind/homelab#2829): tell a long session how big its
# context is, so it hands over while that is still cheap. An agent cannot see
# its own context size; this reads it from the transcript: the last main-chain
# assistant message's input + cache-creation + cache-read tokens.
#
#   < 200k   silent
#   ≥ 200k   nudge: suggest /handoff to the operator in the reply
#   ≥ 250k   wrap up: start no new work, bring in-flight tasks to a stopping
#            point, then offer /handoff (homelab's handoff SKILL.md, "Context
#            budget"; in a repo without one, a summary for a fresh session)
#
# UserPromptSubmit fires on every operator turn past 200k. PostToolUse fires
# only when the context crosses into a new 25k band since the last reminder,
# so a long autonomous stretch (an orchestrator waiting on agents) still gets
# told without a reminder on every tool call. Bands are kept per session under
# $XDG_RUNTIME_DIR (or ~/.local/state: never a shared /tmp).
#
# Silent in subagents (agent_id set) and in the unattended loops
# (AGENT_LOOP_RUN, exported by homelab's scripts/agent-loop.sh): neither hands off.
# Never blocks: every failure path exits 0 with no output.
#
# Thresholds are overridable for the offline test (tests/context-budget.sh).
# Global: registered in ~/.claude/settings.json (stowed from dotfiles), so every
# repo gets it. It moved here from homelab's .claude/hooks (homelab#2976).

NUDGE_AT=${CONTEXT_BUDGET_NUDGE_AT:-200000}
WRAP_AT=${CONTEXT_BUDGET_WRAP_AT:-250000}
BAND=${CONTEXT_BUDGET_BAND:-25000}

[[ -z "${AGENT_LOOP_RUN:-}" ]] || exit 0
command -v jq >/dev/null || exit 0
INPUT=$(cat)
IFS=$'\t' read -r EVENT SESSION TRANSCRIPT AGENT < <(jq -r '[.hook_event_name // "", .session_id // "", .transcript_path // "", .agent_id // ""] | map(if . == "" then "-" else . end) | @tsv' <<<"$INPUT" 2>/dev/null) || exit 0
[[ "$AGENT" == "-" ]] || exit 0
[[ "$EVENT" == UserPromptSubmit || "$EVENT" == PostToolUse ]] || exit 0
[[ -f "$TRANSCRIPT" ]] || exit 0

# Newest main-chain assistant message with real usage (an API-error placeholder
# has none). grep -m bounds the read on a long transcript.
TOKENS=$(tac "$TRANSCRIPT" | grep -m 20 '"type":"assistant"' | jq -rs '
  map(select(.isSidechain != true) | .message.usage // empty
      | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
      | select(. > 0)) | first // 0' 2>/dev/null)
[[ "$TOKENS" =~ ^[0-9]+$ ]] || exit 0
(( TOKENS >= NUDGE_AT )) || exit 0

STATE_DIR="${XDG_RUNTIME_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}}/claude-context-budget"
STATE="$STATE_DIR/${SESSION//[^A-Za-z0-9_-]/_}"
band=$(( TOKENS / BAND ))
last=$(cat "$STATE" 2>/dev/null)
[[ "$last" =~ ^[0-9]+$ ]] || last=-1
if [[ "$EVENT" == PostToolUse ]] && (( band <= last )); then exit 0; fi
mkdir -p "$STATE_DIR" 2>/dev/null && echo "$band" >"$STATE" 2>/dev/null

k=$(( TOKENS / 1000 ))
if (( TOKENS >= WRAP_AT )); then
  MSG="Context budget (homelab#2829): this session's context is ~${k}k tokens, past the $(( WRAP_AT / 1000 ))k wrap-up mark. Start no new work: no new subagents, fan-outs or long operations. Bring what is in flight to a stopping point (let running agents finish or ask them to checkpoint, push branches, note anything half-done), then tell the operator you are ready to /handoff and ask them to confirm. The handoff skill's \"Context budget\" section says more; in a repo without one, offer a summary for a fresh session instead."
elif [[ "$EVENT" == UserPromptSubmit ]]; then
  MSG="Context budget (homelab#2829): this session's context is ~${k}k tokens (nudge at $(( NUDGE_AT / 1000 ))k, wrap-up at $(( WRAP_AT / 1000 ))k). Do what the operator asked, and end your reply with one line suggesting a /handoff (or, in a repo without one, a summary for a fresh session) while the session is still cheap to hand over."
else
  MSG="Context budget (homelab#2829): this session's context is now ~${k}k tokens (nudge at $(( NUDGE_AT / 1000 ))k, wrap-up at $(( WRAP_AT / 1000 ))k). Carry on, and end this turn's reply with one line suggesting a /handoff."
fi

jq -nc --arg e "$EVENT" --arg m "$MSG" '{hookSpecificOutput: {hookEventName: $e, additionalContext: $m}}'
exit 0
