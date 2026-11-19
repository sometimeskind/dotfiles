#!/bin/bash
# Offline tests for ../context-budget.sh (sometimeskind/homelab#2829): fixture transcripts, a
# scratch XDG_RUNTIME_DIR for the band state. No network.
#   bash claude/.claude/hooks/tests/context-budget.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
hook="$here/../context-budget.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export XDG_RUNTIME_DIR="$tmp/run"
unset AGENT_LOOP_RUN
fail=0

# transcript <file> <tokens>: a user line, then a main-chain assistant line whose
# usage sums to <tokens>, a sidechain line and an API-error line with no usage
# (both must be ignored).
transcript() {
  local cache=$(( $2 - 1000 ))
  {
    echo '{"type":"user","message":{"content":"hi"}}'
    echo "{\"type\":\"assistant\",\"isSidechain\":false,\"message\":{\"usage\":{\"input_tokens\":2,\"cache_creation_input_tokens\":998,\"cache_read_input_tokens\":$cache,\"output_tokens\":50}}}"
    echo '{"type":"assistant","isSidechain":true,"message":{"usage":{"input_tokens":5,"cache_read_input_tokens":999999}}}'
    echo '{"type":"assistant","isSidechain":false,"message":{"content":"API Error"}}'
  } >"$1"
}

# run <event> <session> <transcript> [agent_id] → stdout of the hook
run() {
  jq -nc --arg e "$1" --arg s "$2" --arg t "$3" --arg a "${4:-}" \
    '{hook_event_name: $e, session_id: $s, transcript_path: $t} + (if $a == "" then {} else {agent_id: $a} end)' |
    bash "$hook"
}

# check <name> <output> <expect: none|nudge|wrap>
check() {
  local got=none ctx
  ctx=$(jq -r '.hookSpecificOutput.additionalContext // empty' <<<"$2" 2>/dev/null)
  [[ -n "$ctx" ]] && got=nudge
  [[ "$ctx" == *"wrap-up mark"* ]] && got=wrap
  if [[ "$got" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1: want $3, got $got: $2"; fail=1; fi
}

t="$tmp/t.jsonl"
transcript "$t" 150000
check "below 200k: prompt silent"            "$(run UserPromptSubmit s1 "$t")" none
check "below 200k: tool silent"              "$(run PostToolUse s1 "$t")" none

transcript "$t" 205000
check "200k: prompt nudges"                  "$(run UserPromptSubmit s1 "$t")" nudge
check "200k: prompt nudges every turn"       "$(run UserPromptSubmit s1 "$t")" nudge
check "200k: tool silent in same band"       "$(run PostToolUse s1 "$t")" none
check "200k: fresh session tool nudges once" "$(run PostToolUse s2 "$t")" nudge
check "200k: then silent"                    "$(run PostToolUse s2 "$t")" none

transcript "$t" 230000
check "225k band: tool nudges again"         "$(run PostToolUse s2 "$t")" nudge
check "225k band: then silent"               "$(run PostToolUse s2 "$t")" none

transcript "$t" 251000
check "250k: tool wraps up"                  "$(run PostToolUse s2 "$t")" wrap
check "250k: tool silent in same band"       "$(run PostToolUse s2 "$t")" none
check "250k: prompt wraps up"                "$(run UserPromptSubmit s2 "$t")" wrap

transcript "$t" 300000
check "300k: tool wraps up again"            "$(run PostToolUse s2 "$t")" wrap

check "subagent silent"                      "$(run UserPromptSubmit s3 "$t" agent-1)" none
check "loop silent"                          "$(AGENT_LOOP_RUN=r1 run UserPromptSubmit s3 "$t")" none
check "missing transcript silent"            "$(run UserPromptSubmit s3 "$tmp/nope.jsonl")" none
check "other event silent"                   "$(run Stop s3 "$t")" none
check "garbage input silent"                 "$(echo 'not json' | bash "$hook")" none

exit $fail
