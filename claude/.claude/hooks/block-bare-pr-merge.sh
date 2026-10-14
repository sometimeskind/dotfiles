#!/bin/bash
# PreToolUse hook: gate `gh pr merge` from an agent's Bash tool on the
# operator's GitHub approval (#1607, #2179).
#
# Dependency PRs are merged only through scripts/agent-merge.sh, which
# applies the protected-path / green-CI / author policy and logs the merge.
# Any other PR may be merged with a plain `gh pr merge <n|url> ...` once the
# operator has approved it on GitHub: their latest deciding review is
# APPROVED and was left on the PR's current head commit. The hook asks GitHub
# itself, so an agent never asserts an approval (the old OPERATOR_APPROVED=1
# marker did, and auto mode's classifier rightly read it as a bypass). The
# trunk ruleset already requires that review for code-owned paths; this gate
# extends it to every agent merge and lets the agent choose when to merge.
#
# The merge must carry `--match-head-commit <approved sha>`, so GitHub itself
# refuses it if the head moved after this check (a `git push && gh pr merge`)
# or if the command reaches a different PR than the one parsed here (a shell
# or gh parse this regex reads differently). GH_REPO/GH_HOST prefixes are
# denied for the same reason. This is still a tripwire, not a boundary: an
# aliased or wrapped invocation (`bash -c`, a gh alias) is never seen here;
# the ruleset's code-owner review is the boundary for code-owned paths.
#
# The REST merge endpoint stays blocked outright. The unattended loops are
# held by their tool allowlist (ucore/agent-loops/settings-*.json), which
# denies `gh pr merge` whatever this hook says. Fails closed on any error.
#
# Registered by the repo's .claude/settings.json (PreToolUse, matcher Bash),
# so it applies to every session in this checkout without a dotfiles change.
# Canonical copy: homelab ucore/claude-hooks/. Tests: tests/block-bare-pr-merge.sh.

APPROVER=${MERGE_HOOK_APPROVER:-sometimeskind}
GH=${MERGE_HOOK_GH:-gh}

deny() { echo "Blocked: $*" >&2; exit 2; }

command -v jq >/dev/null || deny "block-bare-pr-merge: jq missing"
INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT") || deny "block-bare-pr-merge: cannot parse hook input"
CWD=$(jq -r '.cwd // empty' <<<"$INPUT")
FLAT=$(printf '%s' "$COMMAND" | sed 's/\\$//' | tr '\n\r' '  ')

if grep -qE 'gh[[:space:]]+api[^|;&]*/pulls/[0-9]+/merge' <<<"$FLAT"; then
  deny "PR merge through the REST API. Use gh pr merge <n> once the operator has approved the PR on GitHub; dependency PRs go through scripts/agent-merge.sh <pr>."
fi

# Command position only (start, or after ; & | $( ), with any env-assignment
# or `env` prefix; a mention mid-sentence in a commit message, a doc line or
# a settings rule is not a merge. A heredoc line that STARTS with the command
# is, and is checked like any other.
M='gh[[:space:]]+pr[[:space:]]+merge'
CP='(^|[;&|]|\$\()[[:space:]]*'
ENV='(env[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
mapfile -t merges < <(grep -oE "${CP}${ENV}${M}([[:space:]]+[^;&|)]*)?" <<<"$FLAT")
((${#merges[@]})) || exit 0

grep -qE '(^|[^A-Za-z0-9_])GH_(REPO|HOST)=' <<<"$FLAT" &&
  deny "GH_REPO/GH_HOST in a merge command; name the repo with --repo owner/name or the PR URL."

# The repo a bare number refers to: the session's cwd, unless the command may
# move elsewhere first, in which case it must name the repo.
moves=0
grep -qE '(^|[;&|(]|[[:space:]])(cd|pushd)[[:space:]]|git[[:space:]]+-C[[:space:]]' <<<"$FLAT" && moves=1

default_repo() {
  local url
  url=$(git -C "${CWD:-.}" remote get-url origin 2>/dev/null) || return 1
  url=${url%.git}
  [[ "$url" =~ github\.com[:/]([^/]+/[^/]+)$ ]] || return 1
  echo "${BASH_REMATCH[1]}"
}

HELP="Ask the operator to approve it on GitHub (the bot requests their review), then merge with gh pr merge <n>. Dependency PRs go through scripts/agent-merge.sh <pr>."

for m in "${merges[@]}"; do
  args=${m#*merge}
  read -ra tok <<<"$args"
  pr=${tok[0]:-} repo="" match=""
  for ((i = 0; i < ${#tok[@]}; i++)); do
    case ${tok[i]} in
      --repo=*) repo=${tok[i]#--repo=} ;;
      --repo | -R) repo=${tok[i + 1]:-} ;;
      -R*) repo=${tok[i]#-R} ;;
      --match-head-commit=*) match=${tok[i]#--match-head-commit=} ;;
      --match-head-commit) match=${tok[i + 1]:-} ;;
    esac
  done
  if [[ "$pr" =~ ^https://github\.com/([^/]+/[^/]+)/pull/([0-9]+)/?$ ]]; then
    repo=${BASH_REMATCH[1]} pr=${BASH_REMATCH[2]}
  elif [[ ! "$pr" =~ ^[0-9]+$ ]]; then
    deny "gh pr merge needs the PR number or URL right after merge, so the hook can check its approval. $HELP"
  fi
  if [[ -z "$repo" ]]; then
    ((moves)) && deny "this command may change directory, so gh pr merge must name the repo (--repo owner/name or the PR URL)."
    repo=$(default_repo) || deny "cannot tell which GitHub repo PR $pr is in; pass --repo owner/name."
  fi

  head=$(timeout 20 "$GH" api "repos/$repo/pulls/$pr" --jq .head.sha 2>/dev/null) && [[ -n "$head" ]] ||
    deny "cannot read $repo#$pr from GitHub, so its approval is unknown."
  last=$(timeout 20 "$GH" api --paginate "repos/$repo/pulls/$pr/reviews" --jq \
    ".[] | select(.user.login == \"$APPROVER\" and (.state == \"APPROVED\" or .state == \"CHANGES_REQUESTED\" or .state == \"DISMISSED\")) | \"\(.state) \(.commit_id)\"" \
    2>/dev/null) || deny "cannot read the reviews of $repo#$pr from GitHub, so its approval is unknown."
  last=$(tail -n1 <<<"$last")
  state=${last%% *} commit=${last#* }
  case $state in
    APPROVED) [[ "$commit" == "$head" ]] ||
      deny "$APPROVER approved $repo#$pr at ${commit:0:7}, but its head is now ${head:0:7}. $HELP"
      [[ "$match" == "$head" ]] ||
        deny "$repo#$pr is approved at its head; re-run the merge with --match-head-commit $head so GitHub refuses it if the head moves." ;;
    CHANGES_REQUESTED) deny "$APPROVER requested changes on $repo#$pr. $HELP" ;;
    DISMISSED) deny "$APPROVER's approval of $repo#$pr was dismissed (a later push). $HELP" ;;
    *) deny "$repo#$pr has no approving review from $APPROVER. $HELP" ;;
  esac
done

exit 0
