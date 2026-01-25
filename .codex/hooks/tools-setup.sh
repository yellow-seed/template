#!/usr/bin/env bash
# Codex hook: Direct tool installation for remote environments
# This script installs development tools directly on the host
# when container execution is not available.

set -euo pipefail

LOG_PREFIX="[tools-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

# Only run in remote Codex environment
if [ "${CODEX_REMOTE:-}" != "true" ]; then
  log "Not a remote Codex session (CODEX_REMOTE != true), skipping tools setup"
  exit 0
fi

log "Remote Codex session detected, installing development tools directly..."

# Install basic tools via apt
log "Installing shellcheck, bats, nodejs, npm..."
sudo apt-get update
sudo apt-get install -y shellcheck bats nodejs npm

# Install Go (required for shfmt and actionlint)
if ! command -v go &>/dev/null; then
  log "Installing Go 1.23..."
  wget -q -O /tmp/go.tar.gz https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm /tmp/go.tar.gz
  export PATH="/usr/local/go/bin:$PATH"
else
  log "Go already installed: $(go version)"
fi

# Ensure Go is in PATH
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

# Install shfmt
if ! command -v shfmt &>/dev/null; then
  log "Installing shfmt v3.12.0..."
  go install mvdan.cc/sh/v3/cmd/shfmt@v3.12.0
  sudo cp "$HOME/go/bin/shfmt" /usr/local/bin/
else
  log "shfmt already installed: $(shfmt --version)"
fi

# Install actionlint
if ! command -v actionlint &>/dev/null; then
  log "Installing actionlint v1.7.5..."
  go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.5
  sudo cp "$HOME/go/bin/actionlint" /usr/local/bin/
else
  log "actionlint already installed: $(actionlint --version)"
fi

# Install Prettier
if ! command -v prettier &>/dev/null; then
  log "Installing prettier 3.4.2..."
  sudo npm install -g prettier@3.4.2
else
  log "prettier already installed: $(prettier --version)"
fi

log "Tools setup completed successfully"
log "Installed tools:"
log "  - shellcheck: $(shellcheck --version | head -2 | tail -1)"
log "  - shfmt: $(shfmt --version)"
log "  - bats: $(bats --version)"
log "  - actionlint: $(actionlint --version)"
log "  - prettier: $(prettier --version)"
