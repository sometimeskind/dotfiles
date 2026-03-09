autoload -Uz compinit && compinit
export PATH=$PATH:/home/tom/.local/bin

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval "$(starship init zsh)"

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
