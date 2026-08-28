export PATH="$HOME/.local/bin:$HOME/.docker/bin:$PATH"

# ── Homebrew — cross-platform (macOS Apple Silicon or Linux) ──────────────────
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ── Docker (macOS) ────────────────────────────────────────────────────────────
# Docker Desktop 29+ uses a proxy socket at ~/.docker/run/docker.sock and
# rejects API v1.32 calls (default in shaded docker-java used by Testcontainers).
# DOCKER_HOST points to the proxy socket; JDK_JAVA_OPTIONS sets api.version=1.44
# via the JVM system property that DefaultDockerClientConfig reads (note:
# DOCKER_API_VERSION env var is NOT read by the shaded docker-java in Testcontainers).
if [[ $(uname) == Darwin ]]; then
  export DOCKER_HOST=unix://$HOME/.docker/run/docker.sock
  export JDK_JAVA_OPTIONS="-Dapi.version=1.44"
fi

# ── Locale for non-login shells (mosh over ssh) ───────────────────────────────
# sshd runs `zsh -c mosh-server …` without LANG (/etc/locale.conf only reaches
# login shells). mosh-server adopts the server locale when it is UTF-8 and only
# otherwise falls back to the client's — which uCore (C.utf8 only) rarely has.
# Guarded so terminals that already export LANG (macOS) are left alone.
export LANG="${LANG:-C.UTF-8}"
