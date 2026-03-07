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
# Load secrets from 1Password
if command -v op &>/dev/null; then
  export GITHUB_PERSONAL_ACCESS_TOKEN=$(op read "op://personal/Homelab PAT/token")
fi

[[ $commands[kubectl] ]] && source <(kubectl completion zsh) && compdef k=kubectl
alias k=kubectl

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
