#!/bin/bash
# PreToolUse hook: deny a bare `gh pr merge` (and the REST merge endpoint)
# from an agent's Bash tool (#1607).
#
# Dependency PRs are merged only through scripts/agent-merge.sh, which
# applies the protected-path / green-CI / author policy and logs the merge.
# A human PR the operator has approved in the conversation is merged with
# the explicit marker `OPERATOR_APPROVED=1 gh pr merge ...` — the marker is
# a deliberate "I was told to" step, nothing more. This hook is a tripwire
# against agent drift, not a boundary: the unattended loops are held by
# their tool allowlist (ucore/agent-loops/settings-*.json), which never
# permits either form.
#
# Registered by the repo's .claude/settings.json (PreToolUse, matcher Bash),
# so it applies to every session in this checkout without a dotfiles change.
# Canonical copy: homelab ucore/claude-hooks/.

command -v jq >/dev/null || { echo "block-bare-pr-merge: jq missing — denying" >&2; exit 2; }
INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT") || { echo "block-bare-pr-merge: cannot parse hook input — denying" >&2; exit 2; }
FLAT=$(printf '%s' "$COMMAND" | sed 's/\\$//' | tr '\n\r' '  ')

# Command position only (start, or after ; & | $( ), with any env-assignment
# or `env` prefix; a mention mid-sentence in a commit message, a doc line or
# a settings rule is not a merge — a heredoc line that STARTS with the
# command is, and is blocked. Of the matches, only those whose prefix is
# exactly OPERATOR_APPROVED=1 are allowed; any other bare form is denied.
M='gh[[:space:]]+pr[[:space:]]+merge'
CP='(^|[;&|]|\$\()[[:space:]]*'
ENV='(env[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
total=$(grep -oE "${CP}${ENV}${M}" <<<"$FLAT" | wc -l)
approved=$(grep -oE "${CP}OPERATOR_APPROVED=1[[:space:]]+${M}" <<<"$FLAT" | wc -l)
api=$(grep -cE 'gh[[:space:]]+api[^|;&]*/pulls/[0-9]+/merge' <<<"$FLAT")

if (( total > approved || api > 0 )); then
  echo "Blocked: bare PR merge. Dependency PRs go through scripts/agent-merge.sh <pr> (policy gate + log). A human PR the user has explicitly approved in this conversation: re-run as OPERATOR_APPROVED=1 gh pr merge <pr> ..." >&2
  exit 2
fi

exit 0
