#!/bin/bash
# Development Environment Setup Script for Codex
# This script replicates the functionality of the Dockerfile since Codex
# runs in a container environment where Docker commands are not available.
#
# This script:
# - Installs shellcheck
# - Installs Go 1.23
# - Installs shfmt v3.12.0
# - Installs actionlint v1.7.5
# - Installs Node.js/npm
# - Installs Prettier v3.4.2
# - Creates lint-shell and lint-docs helper scripts
#
# Features:
# - Idempotent: skips already installed tools
# - Fail-safe: exits with 0 even on failure
# - Architecture detection (amd64/arm64)
# - Proper logging

set -e

LOG_PREFIX="[env-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

log "Starting development environment setup..."

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
x86_64)
  GO_ARCH="amd64"
  ;;
aarch64 | arm64)
  GO_ARCH="arm64"
  ;;
*)
  log "Unsupported architecture: $ARCH"
  exit 0 # Fail-safe
  ;;
esac

log "Detected architecture: $ARCH (Go: $GO_ARCH)"

# Setup local bin directory
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# Ensure PATH includes local bin
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
  export PATH="$LOCAL_BIN:$PATH"
  # Persist to environment file if available
  if [ -n "$CODEX_ENV_FILE" ]; then
    echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$CODEX_ENV_FILE"
  fi
fi

# Function to check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# 1. Install shellcheck
if command_exists shellcheck; then
  log "shellcheck already installed: $(shellcheck --version | head -2 | tail -1)"
else
  log "Installing shellcheck..."
  if command_exists apt-get; then
    if ! sudo apt-get update -qq && sudo apt-get install -y shellcheck 2>/dev/null; then
      log "Failed to install shellcheck via apt-get, trying alternative method..."
      # Try downloading binary directly
      SHELLCHECK_VERSION="0.10.0"
      TEMP_DIR=$(mktemp -d)
      trap 'rm -rf "$TEMP_DIR"' EXIT
      
      if curl -sL "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.${ARCH}.tar.xz" -o "$TEMP_DIR/shellcheck.tar.xz" 2>/dev/null; then
        tar -xJf "$TEMP_DIR/shellcheck.tar.xz" -C "$TEMP_DIR" 2>/dev/null || true
        if [ -f "$TEMP_DIR/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" ]; then
          mv "$TEMP_DIR/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" "$LOCAL_BIN/shellcheck"
          chmod +x "$LOCAL_BIN/shellcheck"
          log "shellcheck installed successfully"
        fi
      fi
    else
      log "shellcheck installed successfully via apt-get"
    fi
  else
    log "apt-get not available, skipping shellcheck installation"
  fi
fi

# 2. Install Go 1.23
GO_VERSION="1.23.5"
if command_exists go; then
  CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
  log "Go already installed: $CURRENT_GO_VERSION"
else
  log "Installing Go ${GO_VERSION}..."
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TEMP_DIR"' EXIT
  
  GO_TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
  GO_URL="https://go.dev/dl/${GO_TARBALL}"
  
  if curl -sL "$GO_URL" -o "$TEMP_DIR/go.tar.gz"; then
    log "Extracting Go..."
    GO_INSTALL_DIR="$HOME/.local/go"
    mkdir -p "$GO_INSTALL_DIR"
    
    if tar -C "$GO_INSTALL_DIR" -xzf "$TEMP_DIR/go.tar.gz" --strip-components=1; then
      # Add Go to PATH
      if [[ ":$PATH:" != *":$GO_INSTALL_DIR/bin:"* ]]; then
        export PATH="$GO_INSTALL_DIR/bin:$PATH"
        export GOPATH="$HOME/go"
        export PATH="$GOPATH/bin:$PATH"
        
        # Persist to environment file
        if [ -n "$CODEX_ENV_FILE" ]; then
          {
            echo "export PATH=\"$GO_INSTALL_DIR/bin:\$PATH\""
            echo "export GOPATH=\"$HOME/go\""
            echo "export PATH=\"\$GOPATH/bin:\$PATH\""
          } >>"$CODEX_ENV_FILE"
        fi
      fi
      log "Go ${GO_VERSION} installed successfully"
    else
      log "Failed to extract Go"
    fi
  else
    log "Failed to download Go"
  fi
fi

# Ensure GOPATH is set
if [ -z "$GOPATH" ]; then
  export GOPATH="$HOME/go"
  mkdir -p "$GOPATH/bin"
  export PATH="$GOPATH/bin:$PATH"
fi

# 3. Install shfmt v3.12.0
if command_exists shfmt; then
  log "shfmt already installed: $(shfmt --version)"
else
  log "Installing shfmt v3.12.0..."
  if command_exists go; then
    if go install mvdan.cc/sh/v3/cmd/shfmt@v3.12.0 2>/dev/null; then
      # Move to local bin if installed in GOPATH
      if [ -f "$GOPATH/bin/shfmt" ] && [ "$GOPATH/bin" != "$LOCAL_BIN" ]; then
        cp "$GOPATH/bin/shfmt" "$LOCAL_BIN/shfmt"
      fi
      log "shfmt v3.12.0 installed successfully"
    else
      log "Failed to install shfmt"
    fi
  else
    log "Go not available, skipping shfmt installation"
  fi
fi

# 4. Install actionlint v1.7.5
if command_exists actionlint; then
  log "actionlint already installed: $(actionlint --version | head -1)"
else
  log "Installing actionlint v1.7.5..."
  if command_exists go; then
    if go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.5 2>/dev/null; then
      # Move to local bin if installed in GOPATH
      if [ -f "$GOPATH/bin/actionlint" ] && [ "$GOPATH/bin" != "$LOCAL_BIN" ]; then
        cp "$GOPATH/bin/actionlint" "$LOCAL_BIN/actionlint"
      fi
      log "actionlint v1.7.5 installed successfully"
    else
      log "Failed to install actionlint"
    fi
  else
    log "Go not available, skipping actionlint installation"
  fi
fi

# 5. Install Node.js and npm
if command_exists node && command_exists npm; then
  log "Node.js already installed: $(node --version)"
  log "npm already installed: $(npm --version)"
else
  log "Installing Node.js and npm..."
  if command_exists apt-get; then
    if ! sudo apt-get update -qq && sudo apt-get install -y nodejs npm 2>/dev/null; then
      log "Failed to install Node.js via apt-get, trying nvm..."
      # Try installing via nvm
      if ! command_exists nvm; then
        NVM_VERSION="0.40.1"
        if curl -sL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash 2>/dev/null; then
          export NVM_DIR="$HOME/.nvm"
          # shellcheck source=/dev/null
          [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
          
          if command_exists nvm; then
            nvm install --lts 2>/dev/null || log "Failed to install Node.js via nvm"
          fi
        fi
      fi
    else
      log "Node.js and npm installed successfully via apt-get"
    fi
  else
    log "apt-get not available, skipping Node.js installation"
  fi
fi

# 6. Install Prettier v3.4.2
if command_exists npm; then
  if npm list -g prettier 2>/dev/null | grep -q prettier; then
    PRETTIER_VERSION=$(npm list -g prettier 2>/dev/null | grep prettier | awk -F@ '{print $2}')
    log "Prettier already installed: $PRETTIER_VERSION"
  else
    log "Installing Prettier v3.4.2..."
    if npm install -g prettier@3.4.2 2>/dev/null; then
      log "Prettier v3.4.2 installed successfully"
    else
      log "Failed to install Prettier"
    fi
  fi
else
  log "npm not available, skipping Prettier installation"
fi

# 7. Create lint-shell helper script
LINT_SHELL_SCRIPT="$LOCAL_BIN/lint-shell"
if [ -f "$LINT_SHELL_SCRIPT" ]; then
  log "lint-shell script already exists"
else
  log "Creating lint-shell helper script..."
  cat >"$LINT_SHELL_SCRIPT" <<'EOF'
#!/bin/bash
set -e
echo "Running shellcheck..."
find . -name "*.sh" -type f -print0 | xargs -0 shellcheck --severity=warning
echo ""
echo "Running shfmt..."
find . -name "*.sh" -not -name "*.bats" -type f -print0 | xargs -0 shfmt -i 2 -d
echo ""
echo "All linting checks passed!"
EOF
  chmod +x "$LINT_SHELL_SCRIPT"
  log "lint-shell script created successfully"
fi

# 8. Create lint-docs helper script
LINT_DOCS_SCRIPT="$LOCAL_BIN/lint-docs"
if [ -f "$LINT_DOCS_SCRIPT" ]; then
  log "lint-docs script already exists"
else
  log "Creating lint-docs helper script..."
  cat >"$LINT_DOCS_SCRIPT" <<'EOF'
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
EOF
  chmod +x "$LINT_DOCS_SCRIPT"
  log "lint-docs script created successfully"
fi

log "Development environment setup completed successfully!"
log ""
log "Installed tools:"
command_exists shellcheck && log "  - shellcheck: $(shellcheck --version | head -2 | tail -1)"
command_exists go && log "  - go: $(go version | awk '{print $3}')"
command_exists shfmt && log "  - shfmt: $(shfmt --version)"
command_exists actionlint && log "  - actionlint: $(actionlint --version | head -1)"
command_exists node && log "  - node: $(node --version)"
command_exists npm && log "  - npm: $(npm --version)"
command_exists prettier && log "  - prettier: $(prettier --version)"
log ""
log "Helper scripts:"
[ -x "$LINT_SHELL_SCRIPT" ] && log "  - lint-shell: $LINT_SHELL_SCRIPT"
[ -x "$LINT_DOCS_SCRIPT" ] && log "  - lint-docs: $LINT_DOCS_SCRIPT"

exit 0
