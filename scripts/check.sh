#!/usr/bin/env bash
# Run all lint/validation checks for the dotfiles repo.
# Used by the pre-commit hook and can be run manually.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "  OK  $1"; PASS=$((PASS+1)); }
fail() { echo " FAIL $1"; FAIL=$((FAIL+1)); }
skip() { echo " SKIP $1 ($2 not found)"; }

echo "=== dotfiles checks ==="

# zsh syntax check
if command -v zsh &>/dev/null; then
  if zsh -n "$REPO_ROOT/zsh/.zshrc" 2>&1; then
    ok "zsh/.zshrc syntax (zsh -n)"
  else
    fail "zsh/.zshrc syntax (zsh -n)"
  fi
else
  skip "zsh/.zshrc syntax" "zsh"
fi

# shellcheck (optional, best-effort — zsh isn't bash but catches real bugs)
if command -v shellcheck &>/dev/null; then
  if shellcheck --shell=bash --exclude=SC1090,SC1091,SC2296 "$REPO_ROOT/zsh/.zshrc" 2>&1; then
    ok "zsh/.zshrc shellcheck"
  else
    fail "zsh/.zshrc shellcheck"
  fi
else
  skip "zsh/.zshrc shellcheck" "shellcheck"
fi

# JSON validation
if command -v jq &>/dev/null; then
  for f in $(find "$REPO_ROOT" -name "*.json" -not -path "*/.git/*"); do
    if jq . "$f" &>/dev/null; then
      ok "$f (jq)"
    else
      fail "$f (jq)"
    fi
  done
else
  skip "*.json" "jq"
fi

# TOML validation via Python (stdlib in 3.11+)
if python3 -c "import tomllib" &>/dev/null; then
  for f in $(find "$REPO_ROOT" -name "*.toml" -not -path "*/.git/*"); do
    if python3 -c "import tomllib, sys; tomllib.load(open(sys.argv[1],'rb'))" "$f" 2>&1; then
      ok "$f (tomllib)"
    else
      fail "$f (tomllib)"
    fi
  done
else
  skip "*.toml" "python3 tomllib"
fi

# Ghostty config validation
if command -v ghostty &>/dev/null; then
  GHOSTTY_CFG="$REPO_ROOT/ghostty/.config/ghostty/config"
  if [ -f "$GHOSTTY_CFG" ]; then
    if ghostty +validate-config --config-file="$GHOSTTY_CFG" 2>&1; then
      ok "ghostty config"
    else
      fail "ghostty config"
    fi
  fi
else
  skip "ghostty config" "ghostty"
fi

# Secret scan — no plaintext tokens/passwords
if grep -rn \
    -e 'password\s*=\s*[^$({]' \
    -e 'token\s*=\s*[^$({]' \
    -e 'secret\s*=\s*[^$({]' \
    -e 'api_key\s*=\s*[^$({]' \
    --include="*.sh" --include="*.zsh" --include="*.zshrc" \
    --include="*.toml" --include="*.json" --include="*.conf" \
    --exclude-dir=".git" \
    "$REPO_ROOT" 2>/dev/null; then
  fail "secret scan (possible plaintext credentials found above)"
else
  ok "secret scan"
fi

echo ""
echo "=== results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
