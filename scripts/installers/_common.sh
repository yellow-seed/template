#!/bin/bash
set -u
set -o pipefail

LOG_PREFIX="[install-tools]"

log() {
  echo "$LOG_PREFIX $*" >&2
}

STRICT_MODE="${STRICT_MODE:-false}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local/bin}"
ENV_FILE="${ENV_FILE:-}"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC2034
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

fail() {
  log "ERROR: $1"
  if [ "$STRICT_MODE" = "true" ]; then
    exit 1
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_path() {
  mkdir -p "$INSTALL_PREFIX"
  if [[ ":$PATH:" != *":$INSTALL_PREFIX:"* ]]; then
    export PATH="$INSTALL_PREFIX:$PATH"
    if [ -n "$ENV_FILE" ]; then
      echo "export PATH=\"$INSTALL_PREFIX:\$PATH\"" >>"$ENV_FILE"
    fi
  fi
}

use_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    echo ""
  elif command_exists sudo; then
    echo "sudo"
  else
    echo ""
  fi
}

download_file() {
  local url="$1"
  local destination="$2"

  if command_exists curl; then
    curl -fsSL "$url" -o "$destination"
  elif command_exists wget; then
    wget -qO "$destination" "$url"
  else
    fail "curl or wget is required to download $url"
    return 1
  fi
}

trim() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

install_packages() {
  local packages=("$@")
  local sudo_cmd

  if ! command_exists apt-get; then
    fail "apt-get is not available to install ${packages[*]}"
    return 1
  fi

  sudo_cmd=$(use_sudo)
  if [ "${APT_UPDATED:-false}" != "true" ]; then
    if [ -n "${APT_UPDATE_STAMP:-}" ] && [ -f "$APT_UPDATE_STAMP" ]; then
      APT_UPDATED=true
    elif ! $sudo_cmd apt-get update -qq; then
      fail "apt-get update failed"
      return 1
    else
      APT_UPDATED=true
      if [ -n "${APT_UPDATE_STAMP:-}" ]; then
        touch "$APT_UPDATE_STAMP"
      fi
    fi
  fi

  if ! $sudo_cmd apt-get install -y "${packages[@]}"; then
    fail "apt-get install failed for ${packages[*]}"
    return 1
  fi
}

detect_arch() {
  local arch
  arch=$(uname -m)
  case "$arch" in
  x86_64)
    GO_ARCH="amd64"
    SHELLCHECK_ARCH="x86_64"
    export GO_ARCH SHELLCHECK_ARCH
    ;;
  aarch64 | arm64)
    GO_ARCH="arm64"
    SHELLCHECK_ARCH="aarch64"
    export GO_ARCH SHELLCHECK_ARCH
    ;;
  *)
    fail "Unsupported architecture: $arch"
    return 1
    ;;
  esac
}

ensure_gopath() {
  if [ -z "${GOPATH:-}" ]; then
    export GOPATH="$HOME/go"
  fi
  mkdir -p "$GOPATH/bin"
  if [[ ":$PATH:" != *":$GOPATH/bin:"* ]]; then
    export PATH="$GOPATH/bin:$PATH"
    if [ -n "$ENV_FILE" ]; then
      echo "export PATH=\"$GOPATH/bin:\$PATH\"" >>"$ENV_FILE"
    fi
  fi
}
