export PATH="$HOME/.local/bin:$HOME/.docker/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"


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

# ── mosh-server: exit once the client is gone (homelab#2929) ──────────────────
# Moshi starts a new mosh session on every reconnect and never resumes the old
# one, so each reconnect left a mosh-server (plus an attached herdr client)
# behind: 97 in a day on pilot, enough to lag typing. mosh-server exits after
# this many seconds without a packet from its client. It is not an idle
# timeout, so a connected session never expires. A laptop asleep for longer
# loses its mosh session; herdr keeps the tabs, so reconnect and reattach.
export MOSH_SERVER_NETWORK_TMOUT=3600
# Moshi launches mosh-server through `env MOSH_SERVER_NETWORK_TMOUT=86400 …`,
# which overrides the line above for its servers. With this one set, SIGUSR1
# makes a mosh-server exit only once its client has been silent this long; a
# connected server ignores it. Unset, SIGUSR1 kills even a connected server.
# pilot's mosh-server-reaper timer (homelab ucore/pilot-bootstrap.sh) sends
# SIGUSR1, and only to servers that carry this variable.
export MOSH_SERVER_SIGNAL_TMOUT=3600
