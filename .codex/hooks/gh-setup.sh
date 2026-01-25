#!/bin/bash
# This is sample script, and you should verify your own.
# SessionStart hook: GitHub CLI auto-installation for Codex environments
# This script installs gh CLI following best practices: idempotent, fail-safe,
# and proper logging.

set -e

LOG_PREFIX="[codex-gh-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

if [ "${CODEX_REMOTE:-}" != "true" ] && [ "${CODEX_CONTAINER:-}" != "true" ]; then
  log "Codex remote flag not detected; continuing gh setup"
fi

log "Checking gh CLI..."

if command -v gh &>/dev/null; then
  log "gh CLI already available: $(gh --version | head -1)"
  exit 0
fi

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

if [ -x "$LOCAL_BIN/gh" ]; then
  log "gh found in $LOCAL_BIN"
  if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    export PATH="$LOCAL_BIN:$PATH"
    if [ -n "${CODEX_ENV_FILE:-}" ]; then
      echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$CODEX_ENV_FILE"
      log "PATH updated in CODEX_ENV_FILE"
    fi
  fi
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

if [ -n "${CODEX_ENV_FILE:-}" ]; then
  echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$CODEX_ENV_FILE"
  log "PATH persisted to CODEX_ENV_FILE"
fi

log "gh CLI installed successfully: $($LOCAL_BIN/gh --version | head -1)"
exit 0
