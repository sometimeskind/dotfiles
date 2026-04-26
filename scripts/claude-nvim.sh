#!/usr/bin/env bash
# Convert the current tmux window into a Claude + nvim pair:
#   left pane (65%) — nvim, listening on a fixed RPC socket
#   right pane (35%) — claude (or any command passed as args)
#
# Usage:
#   claude-nvim.sh                  # opens nvim in cwd, starts claude
#   claude-nvim.sh src/foo.ts       # opens specific file(s) in nvim
#   claude-nvim.sh --resume         # passes --resume to claude

set -euo pipefail

SOCKET=/tmp/nvim-claude.sock
CLAUDE_ARGS=("${@}")

if [[ -z ${TMUX:-} ]]; then
  echo "error: must be run inside a tmux session" >&2
  exit 1
fi

pane_count=$(tmux list-panes | wc -l)
if [[ $pane_count -gt 1 ]]; then
  echo "warning: window already has $pane_count panes — skipping split" >&2
  echo "Close extra panes first, or open a new window (prefix + c)" >&2
  exit 1
fi

# Split right (35%) for claude; current pane stays on the left for nvim
tmux split-window -h -p 35

# Start claude in the right pane (pane 1)
if [[ ${#CLAUDE_ARGS[@]} -gt 0 && ${CLAUDE_ARGS[0]} == --* ]]; then
  # args look like claude flags — pass them through
  tmux send-keys -t "{right}" "claude ${CLAUDE_ARGS[*]}" Enter
else
  tmux send-keys -t "{right}" "claude" Enter
fi

# Focus the left pane and replace this script with nvim
tmux select-pane -t "{left}"

# Any non-flag args are treated as files to open
files=()
for arg in "${CLAUDE_ARGS[@]}"; do
  [[ $arg == --* ]] || files+=("$arg")
done

exec nvim --listen "$SOCKET" "${files[@]+"${files[@]}"}"
