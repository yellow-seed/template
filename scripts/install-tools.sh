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

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

SHELLCHECK_VERSION="0.10.0"
GO_VERSION="1.23.5"
SHFMT_VERSION="3.12.0"
ACTIONLINT_VERSION="1.7.5"
PRETTIER_VERSION="3.4.2"

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

install_packages() {
  local packages=("$@")
  local sudo_cmd

  if ! command_exists apt-get; then
    fail "apt-get is not available to install ${packages[*]}"
    return 1
  fi

  sudo_cmd=$(use_sudo)
  if ! $sudo_cmd apt-get update -qq; then
    fail "apt-get update failed"
    return 1
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
    ;;
  aarch64 | arm64)
    GO_ARCH="arm64"
    SHELLCHECK_ARCH="aarch64"
    ;;
  *)
    fail "Unsupported architecture: $arch"
    return 1
    ;;
  esac
}

install_shellcheck() {
  if command_exists shellcheck; then
    log "shellcheck already installed: $(shellcheck --version | head -2 | tail -1)"
    return 0
  fi

  log "Installing shellcheck..."
  if install_packages shellcheck; then
    log "shellcheck installed successfully via apt-get"
    return 0
  fi

  if [ -z "${SHELLCHECK_ARCH:-}" ]; then
    fail "shellcheck architecture not available"
    return 1
  fi

  local temp_dir
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  local archive="shellcheck-v${SHELLCHECK_VERSION}.linux.${SHELLCHECK_ARCH}.tar.xz"
  local url="https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/${archive}"

  if download_file "$url" "$temp_dir/shellcheck.tar.xz"; then
    if tar -xJf "$temp_dir/shellcheck.tar.xz" -C "$temp_dir"; then
      if [ -f "$temp_dir/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" ]; then
        cp "$temp_dir/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" "$INSTALL_PREFIX/shellcheck"
        chmod +x "$INSTALL_PREFIX/shellcheck"
        log "shellcheck installed successfully from release archive"
      else
        fail "shellcheck binary not found after extraction"
      fi
    else
      fail "failed to extract shellcheck archive"
    fi
  else
    fail "failed to download shellcheck archive"
  fi
}

install_go() {
  if command_exists go; then
    log "Go already installed: $(go version | awk '{print $3}')"
    return 0
  fi

  if [ -z "${GO_ARCH:-}" ]; then
    fail "Go architecture not available"
    return 1
  fi

  log "Installing Go ${GO_VERSION}..."
  local temp_dir
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  local tarball="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
  local url="https://go.dev/dl/${tarball}"

  if ! download_file "$url" "$temp_dir/go.tar.gz"; then
    fail "failed to download Go ${GO_VERSION}"
    return 1
  fi

  local go_install_dir=""
  if [ -n "${GO_INSTALL_DIR:-}" ]; then
    go_install_dir="$GO_INSTALL_DIR"
  elif [ -w "/usr/local" ] && [ "$INSTALL_PREFIX" = "/usr/local/bin" ]; then
    go_install_dir="/usr/local/go"
  else
    go_install_dir="$HOME/.local/go"
  fi

  rm -rf "$go_install_dir"
  mkdir -p "$go_install_dir"

  if tar -C "$go_install_dir" -xzf "$temp_dir/go.tar.gz" --strip-components=1; then
    if [[ ":$PATH:" != *":$go_install_dir/bin:"* ]]; then
      export PATH="$go_install_dir/bin:$PATH"
      if [ -n "$ENV_FILE" ]; then
        echo "export PATH=\"$go_install_dir/bin:\$PATH\"" >>"$ENV_FILE"
      fi
    fi
    log "Go ${GO_VERSION} installed successfully"
  else
    fail "failed to extract Go"
  fi
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

install_shfmt() {
  if command_exists shfmt; then
    log "shfmt already installed: $(shfmt --version)"
    return 0
  fi

  if ! command_exists go; then
    fail "Go is required to install shfmt"
    return 1
  fi

  log "Installing shfmt v${SHFMT_VERSION}..."
  if GOBIN="$INSTALL_PREFIX" go install "mvdan.cc/sh/v3/cmd/shfmt@v${SHFMT_VERSION}"; then
    log "shfmt v${SHFMT_VERSION} installed successfully"
  else
    fail "failed to install shfmt"
  fi
}

install_actionlint() {
  if command_exists actionlint; then
    log "actionlint already installed: $(actionlint --version | head -1)"
    return 0
  fi

  if ! command_exists go; then
    fail "Go is required to install actionlint"
    return 1
  fi

  log "Installing actionlint v${ACTIONLINT_VERSION}..."
  if GOBIN="$INSTALL_PREFIX" go install "github.com/rhysd/actionlint/cmd/actionlint@v${ACTIONLINT_VERSION}"; then
    log "actionlint v${ACTIONLINT_VERSION} installed successfully"
  else
    fail "failed to install actionlint"
  fi
}

install_node() {
  if command_exists node && command_exists npm; then
    log "Node.js already installed: $(node --version)"
    log "npm already installed: $(npm --version)"
    return 0
  fi

  log "Installing Node.js and npm..."
  if install_packages nodejs npm; then
    log "Node.js and npm installed successfully via apt-get"
    return 0
  fi

  if command_exists nvm; then
    if nvm install --lts; then
      log "Node.js installed successfully via nvm"
      return 0
    fi
  fi

  fail "Failed to install Node.js and npm"
}

install_prettier() {
  if command_exists prettier; then
    log "Prettier already installed: $(prettier --version)"
    return 0
  fi

  if ! command_exists npm; then
    fail "npm is required to install Prettier"
    return 1
  fi

  log "Installing Prettier v${PRETTIER_VERSION}..."
  if npm install -g "prettier@${PRETTIER_VERSION}"; then
    log "Prettier v${PRETTIER_VERSION} installed successfully"
  else
    fail "Failed to install Prettier"
  fi
}

install_helper_script() {
  local script_name="$1"
  local dest_name="$2"
  local source_path="$REPO_ROOT/scripts/${script_name}.sh"
  local dest_path="$INSTALL_PREFIX/$dest_name"

  if [ -x "$dest_path" ]; then
    log "$dest_name already installed"
    return 0
  fi

  if [ -f "$source_path" ]; then
    cp "$source_path" "$dest_path"
    chmod +x "$dest_path"
    log "$dest_name installed"
  else
    fail "$source_path not found"
  fi
}

main() {
  log "Starting tool installation"
  ensure_path

  if ! detect_arch; then
    return 0
  fi

  install_shellcheck
  install_go
  ensure_gopath
  install_shfmt
  install_actionlint
  install_node
  install_prettier

  install_helper_script "lint-shell" "lint-shell"
  install_helper_script "lint-docs" "lint-docs"

  log "Tool installation completed"
}

main "$@"
