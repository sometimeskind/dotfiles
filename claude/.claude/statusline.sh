#!/bin/sh
# Claude Code status line: ccstatusline from a pinned local install (homelab#2957).
# `npx -y ccstatusline@latest` started npm, node and a registry lookup on every
# refresh in every session (~2.6 CPU-s each); the installed copy costs ~0.6.
# Where it isn't installed (a fresh machine), fall back to npx at the pinned
# version. To upgrade: bump CCSL_VERSION, then run `~/.claude/statusline.sh --install`.
CCSL_VERSION=2.2.34
root="$HOME/.local/share/ccstatusline"
bin="$root/$CCSL_VERSION/node_modules/.bin/ccstatusline"

if [ "${1:-}" = --install ]; then
  set -eu
  if [ ! -x "$bin" ]; then
    npm install --prefix "$root/$CCSL_VERSION" --no-fund --no-audit --loglevel=error \
      "ccstatusline@$CCSL_VERSION"
    echo "ccstatusline $CCSL_VERSION installed"
  fi
  # Drop any other version left by an earlier pin.
  for d in "$root"/*; do
    [ "$d" = "$root/$CCSL_VERSION" ] || [ ! -d "$d" ] || rm -rf "$d"
  done
  exit 0
fi

[ -x "$bin" ] && exec "$bin"
exec npx -y "ccstatusline@$CCSL_VERSION"
