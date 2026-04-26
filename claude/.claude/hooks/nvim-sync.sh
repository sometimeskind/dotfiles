#!/usr/bin/env bash
# PostToolUse hook: open the file Claude just edited in a running nvim instance.
#
# Wired into settings.json for Write | Edit | MultiEdit.
# Exits 0 always — hook failures must never interrupt Claude.

set -uo pipefail

# ── 1. Parse file path from JSON stdin ──────────────────────────────────────
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -n $FILE ]] || exit 0

# Resolve relative paths to absolute
FILE=$(realpath -m "$FILE" 2>/dev/null || echo "$FILE")
[[ -e $FILE ]] || exit 0   # skip if file doesn't exist (e.g. failed write)

# ── 2. Locate a running nvim RPC socket ─────────────────────────────────────
find_socket() {
  # Prefer the fixed socket set by claude-nvim.sh
  local fixed=/tmp/nvim-claude.sock
  [[ -S $fixed ]] && { echo "$fixed"; return; }

  # Fall back to any nvim socket in standard locations, preferring one
  # whose cwd matches the current working directory.
  local cwd
  cwd=$(pwd)
  local candidates=()

  # Linux: /tmp/nvim.<user>/<pid>/0  or  /run/user/<uid>/nvim.<pid>/0
  while IFS= read -r s; do
    candidates+=("$s")
  done < <(find /tmp /run/user 2>/dev/null -maxdepth 4 \
            -name "nvim.*.0" -o -name "0" -path "*/nvim*" 2>/dev/null \
          | sort 2>/dev/null || true)

  # macOS: /var/folders/…/T/nvim.*/0
  while IFS= read -r s; do
    candidates+=("$s")
  done < <(find /var/folders 2>/dev/null -maxdepth 6 \
            -path "*/nvim.*/*" -name "0" 2>/dev/null \
          | sort 2>/dev/null || true)

  # Prefer the socket whose nvim is in the same project tree
  for s in "${candidates[@]}"; do
    [[ -S $s ]] || continue
    local nvim_cwd
    nvim_cwd=$(nvim --server "$s" --remote-expr 'getcwd()' 2>/dev/null || true)
    [[ $nvim_cwd == "$cwd"* || $cwd == "$nvim_cwd"* ]] && { echo "$s"; return; }
  done

  # Return first usable socket
  for s in "${candidates[@]}"; do
    [[ -S $s ]] && { echo "$s"; return; }
  done
}

SOCKET=$(find_socket)
[[ -n $SOCKET ]] || exit 0   # no nvim running, nothing to do

# ── 3. Open the file in nvim ─────────────────────────────────────────────────
nvim --server "$SOCKET" --remote "$FILE" 2>/dev/null || true

exit 0
