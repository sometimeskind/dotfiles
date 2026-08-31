#!/bin/bash
# Block any Bash command that uses the admin kubeconfig.
# Claude must surface these commands for the user to run manually.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qE 'KUBECONFIG=[^ ]*admin\.yaml|--kubeconfig[= ][^ ]*admin\.yaml'; then
  echo "Blocked: admin kubeconfig usage is not permitted. Surface this command for the user to run manually instead." >&2
  exit 2
fi

exit 0
