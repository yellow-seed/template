#!/bin/bash
# This is sample script, and you should verify your own.
# SessionStart hook: setup a shell development environment for Codex
# Mirrors Dockerfile setup (shellcheck, Go, shfmt, actionlint, Node.js, Prettier,
# and helper lint scripts). Designed to be idempotent and fail-safe.

LOG_PREFIX="[codex-env-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

LOCAL_BIN="$HOME/.local/bin"
GO_VERSION="1.23.5"
GO_ROOT="$HOME/.local/go"
GO_TARBALL_DIR="$HOME/.local/tmp/go-install"
GOPATH="$HOME/.local/go-path"

mkdir -p "$LOCAL_BIN" "$GOPATH"

add_to_path() {
  local dir="$1"
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
}

persist_path() {
  local dir="$1"
  local export_line="export PATH=\"$dir:\$PATH\""
  if [ -n "${CODEX_ENV_FILE:-}" ]; then
    touch "$CODEX_ENV_FILE"
    if ! grep -Fxq "$export_line" "$CODEX_ENV_FILE"; then
      echo "$export_line" >>"$CODEX_ENV_FILE"
      log "PATH persisted to CODEX_ENV_FILE ($dir)"
    fi
  fi
}

add_to_path "$LOCAL_BIN"
add_to_path "$GO_ROOT/bin"

persist_path "$LOCAL_BIN"
persist_path "$GO_ROOT/bin"

install_packages() {
  if ! command -v apt-get &>/dev/null; then
    log "apt-get not available; skipping package installation"
    return 0
  fi

  local packages=()

  if ! command -v shellcheck &>/dev/null; then
    packages+=(shellcheck)
  fi
  if ! command -v wget &>/dev/null; then
    packages+=(wget)
  fi
  if ! command -v git &>/dev/null; then
    packages+=(git)
  fi
  if ! command -v bats &>/dev/null; then
    packages+=(bats)
  fi
  if ! command -v curl &>/dev/null; then
    packages+=(curl)
  fi
  if ! command -v node &>/dev/null; then
    packages+=(nodejs)
  fi
  if ! command -v npm &>/dev/null; then
    packages+=(npm)
  fi

  if [ "${#packages[@]}" -eq 0 ]; then
    log "System packages already installed"
    return 0
  fi

  local sudo_cmd=""
  if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
      sudo_cmd="sudo"
    else
      log "sudo not available; skipping package installation"
      return 0
    fi
  fi

  log "Installing packages: ${packages[*]}"
  if ! $sudo_cmd apt-get update; then
    log "apt-get update failed; skipping package installation"
    return 0
  fi
  if ! $sudo_cmd apt-get install -y "${packages[@]}"; then
    log "apt-get install failed; skipping package installation"
    return 0
  fi
}

install_go() {
  if command -v go &>/dev/null; then
    local current_version
    current_version=$(go version | awk '{print $3}' | sed 's/^go//')
    if [[ "$current_version" == "$GO_VERSION" || "$current_version" == 1.23* ]]; then
      log "Go already installed: $current_version"
      return 0
    fi
    log "Go version $current_version found; upgrading to $GO_VERSION"
  fi

  local arch
  arch=$(uname -m)
  case "$arch" in
  x86_64)
    arch="amd64"
    ;;
  aarch64 | arm64)
    arch="arm64"
    ;;
  *)
    log "Unsupported architecture for Go: $arch"
    return 0
    ;;
  esac

  local tarball="go${GO_VERSION}.linux-${arch}.tar.gz"
  local url="https://go.dev/dl/${tarball}"

  mkdir -p "$GO_TARBALL_DIR"
  rm -rf "$GO_TARBALL_DIR"/*

  log "Downloading Go ${GO_VERSION} for ${arch}..."
  if command -v curl &>/dev/null; then
    if ! curl -fsSL "$url" -o "$GO_TARBALL_DIR/$tarball"; then
      log "Failed to download Go with curl"
      return 0
    fi
  elif command -v wget &>/dev/null; then
    if ! wget -qO "$GO_TARBALL_DIR/$tarball" "$url"; then
      log "Failed to download Go with wget"
      return 0
    fi
  else
    log "Neither curl nor wget available for Go download"
    return 0
  fi

  log "Extracting Go..."
  rm -rf "$GO_ROOT"
  mkdir -p "$GO_ROOT"
  if ! tar -xzf "$GO_TARBALL_DIR/$tarball" -C "$GO_TARBALL_DIR"; then
    log "Failed to extract Go tarball"
    return 0
  fi
  if ! mv "$GO_TARBALL_DIR/go" "$GO_ROOT"; then
    log "Failed to install Go"
    return 0
  fi

  add_to_path "$GO_ROOT/bin"
  persist_path "$GO_ROOT/bin"
  log "Go installed: $GO_VERSION"
}

install_shfmt() {
  local required_version="v3.12.0"
  if command -v shfmt &>/dev/null; then
    local current
    current=$(shfmt --version 2>/dev/null)
    if [ "$current" = "$required_version" ]; then
      log "shfmt already installed: $current"
      return 0
    fi
  fi

  if ! command -v go &>/dev/null; then
    log "Go not available; skipping shfmt installation"
    return 0
  fi

  log "Installing shfmt $required_version..."
  if ! GOBIN="$LOCAL_BIN" GOPATH="$GOPATH" go install mvdan.cc/sh/v3/cmd/shfmt@${required_version}; then
    log "Failed to install shfmt"
    return 0
  fi
}

install_actionlint() {
  local required_version="1.7.5"
  if command -v actionlint &>/dev/null; then
    local current
    current=$(actionlint -version 2>/dev/null | awk '{print $3}')
    if [ "$current" = "$required_version" ]; then
      log "actionlint already installed: $current"
      return 0
    fi
  fi

  if ! command -v go &>/dev/null; then
    log "Go not available; skipping actionlint installation"
    return 0
  fi

  log "Installing actionlint $required_version..."
  if ! GOBIN="$LOCAL_BIN" GOPATH="$GOPATH" go install github.com/rhysd/actionlint/cmd/actionlint@v${required_version}; then
    log "Failed to install actionlint"
    return 0
  fi
}

install_prettier() {
  local required_version="3.4.2"
  if command -v prettier &>/dev/null; then
    local current
    current=$(prettier --version 2>/dev/null)
    if [ "$current" = "$required_version" ]; then
      log "Prettier already installed: $current"
      return 0
    fi
  fi

  if ! command -v npm &>/dev/null; then
    log "npm not available; skipping Prettier installation"
    return 0
  fi

  log "Installing Prettier $required_version..."
  if ! npm install -g "prettier@${required_version}"; then
    log "Failed to install Prettier"
    return 0
  fi
}

install_lint_scripts() {
  local lint_shell="$LOCAL_BIN/lint-shell"
  local lint_docs="$LOCAL_BIN/lint-docs"

  cat <<'SCRIPT' >"$lint_shell"
#!/bin/bash
set -e

echo "Running shellcheck..."
find . -name "*.sh" -type f -print0 | xargs -0 shellcheck --severity=warning

echo ""
echo "Running shfmt..."
find . -name "*.sh" -not -name "*.bats" -type f -print0 | xargs -0 shfmt -i 2 -d

echo ""
echo "All linting checks passed!"
SCRIPT

  chmod +x "$lint_shell"

  cat <<'SCRIPT' >"$lint_docs"
#!/bin/bash
set -e

echo "Running Prettier (Markdown)..."
prettier --check "README.md" "AGENTS.md" "CLAUDE.md" "docs/**/*.md" ".github/**/*.md"

echo ""
echo "Running Prettier (YAML)..."
prettier --check "compose.yml" "codecov.yml" ".github/**/*.{yml,yaml}"

echo ""
echo "Running Prettier (JSON)..."
prettier --check ".github/**/*.json"

echo ""
echo "All document linting checks passed!"
SCRIPT

  chmod +x "$lint_docs"

  log "Helper scripts installed to $LOCAL_BIN"
}

log "Starting Codex environment setup..."
install_packages
install_go
install_shfmt
install_actionlint
install_prettier
install_lint_scripts
log "Codex environment setup completed"
exit 0
