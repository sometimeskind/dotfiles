autoload -Uz compinit

# ── SDKMAN ────────────────────────────────────────────────────────────────────
# Must be sourced before compinit to avoid __sdkman_* function-not-found warnings.
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

compinit

# History
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
# shellcheck disable=SC2034  # SAVEHIST is read directly by zsh
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

eval "$(starship init zsh)"

# ── tmux (install: brew install tmux) ─────────────────────────────────────────
# Auto-attach to or create the main session on terminal open.
# Useful for SSH workflows — keeps sessions alive across disconnects.
if [[ -z $TMUX ]] && command -v tmux &>/dev/null; then
  tmux new-session -A -s main
fi

alias aptup="sudo apt update && sudo apt dist-upgrade -yq && sudo apt autoremove -yq"
alias pipxup="pipx upgrade-all"
alias brewup="brew upgrade --greedy"
alias flatup="flatpak update -y"
alias yolo="aptup && brewup && flatup && pipxup"

export EDITOR="/usr/bin/code"

# Lazy-load secrets from 1Password before the first command
if command -v op &>/dev/null; then
  _op_secrets_loaded=false
  _load_op_secrets() {
    if ! $_op_secrets_loaded; then
      _op_secrets_loaded=true
      GITHUB_PERSONAL_ACCESS_TOKEN=$(op read "op://personal/Homelab PAT/token" 2>/dev/null)
      export GITHUB_PERSONAL_ACCESS_TOKEN
    fi
  }
  autoload -U add-zsh-hook
  add-zsh-hook preexec _load_op_secrets
fi

command -v kubectl &>/dev/null && source <(kubectl completion zsh) && compdef k=kubectl
alias k=kubectl

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ── fzf (install: brew install fzf fd) ────────────────────────────────────────
# Enables: Ctrl+R (history), Ctrl+T (file picker), Alt+C (cd into subdir)
if command -v fzf &>/dev/null; then
  eval "$(fzf --zsh)"
  export FZF_DEFAULT_OPTS="--multi --height=40% --layout=reverse --border \
    --color=bg+:#2b2b2b,bg:#1a1a1a,spinner:#f8f8f2,hl:#66d9ef \
    --color=fg:#f8f8f2,header:#66d9ef,info:#a6e22e,pointer:#f92672 \
    --color=marker:#f92672,fg+:#f8f8f2,prompt:#a6e22e,hl+:#66d9ef"
  # Use fd if available — faster than find, respects .gitignore
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
  fi
fi

# ── zoxide (install: brew install zoxide) ─────────────────────────────────────
# z <query>  — jump to most frecent matching dir
# zi         — interactive fzf picker (requires fzf)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ── eza (install: brew install eza) ───────────────────────────────────────────
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lah --icons --group-directories-first --git"
  alias lt="eza --tree --icons -L 2"
fi

# ── bat (install: brew install bat) ───────────────────────────────────────────
if command -v bat &>/dev/null; then
  alias cat="bat --paging=never"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
