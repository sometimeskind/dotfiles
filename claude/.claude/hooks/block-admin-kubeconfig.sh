#!/bin/bash
# PreToolUse hook: block Bash commands that reach for admin credentials —
# the admin kubeconfig (any path ending in admin.yaml) and talosctl
# credential minting (`talosctl kubeconfig`, `talosctl config new`).
# Claude must surface these commands for the operator to run instead.
#
# This is a tripwire against agent drift, NOT a security boundary (#1511):
# the boundary is that the credentials are not on the box. Registered under
# PreToolUse (matcher: Bash) — PermissionRequest never fires in
# bypass-permissions sessions, which is how the old registration was bypassed.
#
# Canonical copy: homelab ucore/claude-hooks/ (installed by pilot-bootstrap.sh
# into ~/.claude/hooks/; if that path is stowed from dotfiles, commit the
# drift there to keep parity).

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qE 'admin\.yaml|talosctl[^|;&]*[[:space:]]kubeconfig|talosctl[^|;&]*[[:space:]]config[[:space:]]+new'; then
  echo "Blocked: admin credential access (admin kubeconfig / talosctl kubeconfig / talosctl config new) is operator-only. Surface this command for the user to run manually instead." >&2
  exit 2
fi

exit 0
