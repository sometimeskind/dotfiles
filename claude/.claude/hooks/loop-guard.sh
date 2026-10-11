#!/bin/bash
# PreToolUse hook for the unattended loops (#1607): the "never" list that a
# prefix allowlist cannot express. Registered only by
# ucore/agent-loops/settings-*.json, so interactive sessions never see it.
#
#   kubectl delete   never --force / --grace-period / --all / -A / selectors
#                    (one named pod or job at a time), never another kubeconfig
#   git              never force-push, a refspec onto trunk/main, rebase,
#                    reset --hard, branch -D, --no-verify (the wrapper owns
#                    the trunk push)
#   gh               never close/edit/ready/merge/review a PR, never a write
#                    via gh api, never repo/workflow/secret/auth subcommands.
#                    Issues are open-and-comment only (#1663): create,
#                    comment, list and view are allowed, close/reopen/edit/
#                    delete/transfer/pin/lock are not — a loop never retires
#                    its own ticket, and it appends rather than rewriting
#   infra window     no write action while /run/user/<uid>/infra-session
#                    exists (the wrapper skipped at start; this covers a
#                    window opened mid-run)
#
# Matching is done on a normalised copy: line continuations and newlines
# joined, quoted strings blanked (a PR comment quoting a forbidden command
# is not that command), subcommands anchored to command position. Fails
# closed on unparsable input. Tripwire semantics like the other hooks:
# exit 2 denies the call and the message reaches the model, which must log
# the denial and move on.

command -v jq >/dev/null || { echo "loop-guard: jq missing — denying" >&2; exit 2; }
INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT") || { echo "loop-guard: cannot parse hook input — denying" >&2; exit 2; }
[[ -n "$COMMAND" ]] || exit 0
deny() { echo "Blocked by loop-guard: $1" >&2; exit 2; }

# One line, no continuations; then quoted strings blanked to "" / ''.
FLAT=$(printf '%s' "$COMMAND" | sed 's/\\$//' | tr '\n\r' '  ')
BARE=$(printf '%s' "$FLAT" | sed -E "s/\"([^\"\\\\]|\\\\.)*\"/\"\"/g; s/'[^']*'/''/g")
# Command position: start, or after ; & | ( or $( — with optional env assignments.
CP='(^|[;&|(][[:space:]]*|\$\([[:space:]]*)([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'

# --- kubectl delete: flags anywhere in the segment (quotes are rare there; use FLAT)
if grep -qE "${CP}kubectl[[:space:]]+delete" <<<"$BARE"; then
  grep -qE -- '--force|--grace-period|--all(=|[[:space:]]|$)|--all-namespaces|(^|[[:space:]])-A([[:space:]]|$)|(^|[[:space:]])-l([[:space:]]|=|[^[:space:]])|--selector|--field-selector|--cascade' <<<"$FLAT" \
    && deny "kubectl delete with --force/--grace-period/--all/-A/selector — delete one named pod or job at a time"
fi
grep -qE "kubectl[^;&]*--kubeconfig|${CP}KUBECONFIG=" <<<"$BARE" && deny "kubectl with a non-default kubeconfig"

# --- git
GIT="${CP}git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?"
if grep -qE "${GIT}push" <<<"$BARE"; then
  grep -qE "${GIT}push[^;&|]*([[:space:]](-[a-zA-Z]*f[a-zA-Z]*|--force|--force-with-lease)([[:space:]]|=|$)|[[:space:]][^[:space:]]*:(refs/heads/)?(trunk|main)([[:space:]]|$)|[[:space:]](origin[[:space:]]+)?(trunk|main)([[:space:]]|$))" <<<"$BARE" \
    && deny "git force-push / push to trunk or main — loops only push their own fix/loop-* branches; the wrapper commits the log"
fi
grep -qE "${GIT}(rebase|reset[[:space:]]+--hard|branch[^;&|]*[[:space:]]-D|filter-branch)" <<<"$BARE" && deny "git rebase / reset --hard / branch -D — not a loop action"
grep -qE "${GIT}[a-z-]+[^;&|]*--no-verify" <<<"$BARE" && deny "git --no-verify"

# --- gh
GH="${CP}gh[[:space:]]+"
grep -qE "${GH}pr[[:space:]]+(close|edit|ready|merge|review|reopen|lock|checkout)" <<<"$BARE" && deny "gh pr close/edit/ready/merge/review — not a loop action; comment and skip instead"
grep -qE "${GH}api[^;&]*[[:space:]](-X|--method|-f|-F|--field|--raw-field|--input)([[:space:]]|=)" <<<"$BARE" && deny "gh api write — loops read via gh api only"
grep -qE "${GH}(repo|release[[:space:]]+(create|delete|edit|upload)|workflow|secret|variable|auth)" <<<"$BARE" && deny "gh repo/release-write/workflow/secret/variable/auth — not a loop action"
grep -qE "${GH}issue[[:space:]]+(close|reopen|delete|edit|transfer|pin|unpin|lock|unlock)" <<<"$BARE" && deny "gh issue close/reopen/edit/delete/transfer/pin/lock — a loop opens issues and comments on them; a human closes them, and an update is a comment, never a rewrite of the body"

# --- write actions while an infra window is open: the operator may be mid-apply
if [[ -d "/run/user/$(id -u)/infra-session" ]]; then
  grep -qE "${CP}(kubectl[[:space:]]+delete|git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(push|commit)|gh[[:space:]]+(pr|issue)[[:space:]]+(create|comment)|[^[:space:]]*agent-merge\.sh)" <<<"$BARE" \
    && deny "an infra session window is open (/run/user/$(id -u)/infra-session) — no write actions; log a verdict of skipped reason=infra-window-open and stop"
fi

exit 0
