#!/bin/bash
# Block shell commands containing quoted visual separators (e.g. "-----")
# These trigger "Command contains quoted characters in flag names" permission warnings.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qP '"[- ]{4,}"'; then
  echo "Blocked: command contains a quoted dash/space separator string (e.g. \"-----\"). Remove it and try again." >&2
  exit 2
fi

exit 0
