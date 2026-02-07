#!/bin/bash
# Common GitHub CLI setup script for remote environments
# This script installs gh CLI and gh-sub-issue extension when running remotely.

set -e

LOG_PREFIX="[gh-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

install_gh_sub_issue() {
  local gh_cmd="$1"
  log "Checking gh-sub-issue extension..."

  if "$gh_cmd" extension list 2>/dev/null | grep -q "yahsan2/gh-sub-issue"; then
    log "gh-sub-issue extension already installed"
    return 0
  fi

  log "Installing gh-sub-issue extension..."
  if "$gh_cmd" extension install yahsan2/gh-sub-issue 2>/dev/null; then
    log "gh-sub-issue extension installed successfully"
  else
    log "Failed to install gh-sub-issue extension (non-critical, continuing)"
  fi
}

if [ -z "${REMOTE_ENV_VAR:-}" ]; then
  log "REMOTE_ENV_VAR is not set, skipping gh setup"
  exit 0
fi

REMOTE_ENV_VALUE="${!REMOTE_ENV_VAR:-}"
if [ "$REMOTE_ENV_VALUE" != "true" ]; then
  log "Not a remote session, skipping gh setup"
  exit 0
fi

log "Remote session detected, checking gh CLI..."

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

if command -v gh &>/dev/null; then
  log "gh CLI already available: $(gh --version | head -1)"
  install_gh_sub_issue "gh"
  exit 0
fi

if [ -x "$LOCAL_BIN/gh" ]; then
  log "gh found in $LOCAL_BIN"
  if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    export PATH="$LOCAL_BIN:$PATH"
    if [ -n "${ENV_FILE:-}" ]; then
      echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$ENV_FILE"
      log "PATH updated in ENV_FILE"
    fi
  fi
  install_gh_sub_issue "$LOCAL_BIN/gh"
  exit 0
fi

log "Installing gh CLI to $LOCAL_BIN..."

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

ARCH=$(uname -m)
case "$ARCH" in
x86_64)
  GH_ARCH="amd64"
  ;;
aarch64 | arm64)
  GH_ARCH="arm64"
  ;;
*)
  log "Unsupported architecture: $ARCH"
  exit 0
  ;;
esac

GH_VERSION="2.62.0"
GH_TARBALL="gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz"
GH_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}/${GH_TARBALL}"

log "Downloading gh v${GH_VERSION} for ${GH_ARCH}..."

if ! curl -sL "$GH_URL" -o "$TEMP_DIR/$GH_TARBALL"; then
  log "Failed to download gh CLI"
  exit 0
fi

log "Extracting..."
if ! tar -xzf "$TEMP_DIR/$GH_TARBALL" -C "$TEMP_DIR"; then
  log "Failed to extract gh CLI"
  exit 0
fi

if ! mv "$TEMP_DIR/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh" "$LOCAL_BIN/gh"; then
  log "Failed to install gh CLI"
  exit 0
fi

chmod +x "$LOCAL_BIN/gh"

export PATH="$LOCAL_BIN:$PATH"

if [ -n "${ENV_FILE:-}" ]; then
  echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$ENV_FILE"
  log "PATH persisted to ENV_FILE"
fi

log "gh CLI installed successfully: $($LOCAL_BIN/gh --version | head -1)"

install_gh_sub_issue "$LOCAL_BIN/gh"

exit 0
