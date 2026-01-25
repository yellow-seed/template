#!/bin/bash
# SessionStart hook: Podman setup for Codex environments
# Installs podman and podman-compose, optionally sets docker aliases,
# and can verify Dockerfile builds/runs using Podman.
#
# Features:
# - Idempotent: skips already installed tools
# - Fail-safe: exits with 0 even on failure
# - Proper logging

set -e

LOG_PREFIX="[podman-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

command_exists() {
  command -v "$1" &>/dev/null
}

ENABLE_ALIASES=false
VERIFY_DOCKERFILE=false
VERIFY_COMPOSE=false

for arg in "$@"; do
  case "$arg" in
    --enable-aliases)
      ENABLE_ALIASES=true
      ;;
    --verify-dockerfile)
      VERIFY_DOCKERFILE=true
      ;;
    --verify-compose)
      VERIFY_COMPOSE=true
      ;;
  esac
done

# Only run in remote Codex environment
if [ "$CODEX_REMOTE" != "true" ]; then
  log "Not a remote Codex session, skipping podman setup"
  exit 0
fi

log "Remote Codex session detected, checking podman..."

if command_exists podman; then
  log "podman already installed: $(podman --version)"
else
  if command_exists apt-get; then
    log "Installing podman via apt-get..."
    if ! (sudo apt-get update -qq && sudo apt-get install -y podman 2>/dev/null); then
      log "Failed to install podman via apt-get"
    fi
  else
    log "apt-get not available, skipping podman installation"
  fi
fi

if command_exists podman; then
  log "podman available: $(podman --version)"
else
  log "podman is not available after installation attempt"
fi

log "Checking podman-compose..."
if command_exists podman-compose; then
  log "podman-compose already installed: $(podman-compose --version 2>/dev/null || echo 'version unavailable')"
else
  if command_exists apt-get; then
    log "Installing podman-compose via apt-get..."
    if ! (sudo apt-get update -qq && sudo apt-get install -y podman-compose 2>/dev/null); then
      log "Failed to install podman-compose via apt-get"
    fi
  else
    log "apt-get not available, skipping podman-compose installation"
  fi
fi

if command_exists podman-compose; then
  log "podman-compose available: $(podman-compose --version 2>/dev/null || echo 'version unavailable')"
else
  log "podman-compose is not available after installation attempt"
fi

if $ENABLE_ALIASES; then
  log "Setting docker compatibility aliases"
  alias docker=podman
  alias docker-compose=podman-compose

  if [ -n "$CODEX_ENV_FILE" ]; then
    if ! grep -Fxq "alias docker=podman" "$CODEX_ENV_FILE" 2>/dev/null; then
      echo "alias docker=podman" >>"$CODEX_ENV_FILE"
    fi
    if ! grep -Fxq "alias docker-compose=podman-compose" "$CODEX_ENV_FILE" 2>/dev/null; then
      echo "alias docker-compose=podman-compose" >>"$CODEX_ENV_FILE"
    fi
    log "Aliases persisted to CODEX_ENV_FILE"
  else
    log "CODEX_ENV_FILE not set; aliases applied to current shell only"
  fi
else
  log "Alias setup skipped (use --enable-aliases to enable)"
fi

if $VERIFY_DOCKERFILE; then
  if ! command_exists podman; then
    log "Cannot verify Dockerfile; podman is not available"
  elif [ ! -f "Dockerfile" ]; then
    log "Cannot verify Dockerfile; Dockerfile not found in $(pwd)"
  else
    log "Verifying Dockerfile build with podman..."
    if podman build -t dev-env .; then
      log "Podman build succeeded"
    else
      log "Podman build failed"
    fi

    log "Verifying container run with podman..."
    if podman run --rm -v "$(pwd)":/workspace -w /workspace dev-env lint-docs; then
      log "Podman run succeeded"
    else
      log "Podman run failed"
    fi
  fi
else
  log "Dockerfile verification skipped (use --verify-dockerfile to enable)"
fi

if $VERIFY_COMPOSE; then
  if ! command_exists podman; then
    log "Cannot verify compose build; podman is not available"
  elif ! command_exists podman-compose; then
    log "Cannot verify compose build; podman-compose is not available"
  elif [ ! -f "compose.yml" ] && [ ! -f "docker-compose.yml" ]; then
    log "Cannot verify compose build; compose file not found in $(pwd)"
  else
    log "Verifying podman compose build..."
    if podman compose build; then
      log "Podman compose build succeeded"
    else
      log "Podman compose build failed"
    fi
  fi
else
  log "Compose verification skipped (use --verify-compose to enable)"
fi

log "Podman setup completed"
exit 0
