#!/bin/bash
# Docker Setup Script for Codex
# This script checks Docker/Docker Compose availability and installs
# missing components when possible.
#
# Features:
# - Idempotent: skips already installed tools
# - Fail-safe: exits with 0 even on failure
# - Docker daemon/socket detection
# - Docker Compose v2/v1 fallback
# - Clear logging and guidance

set -e

LOG_PREFIX="[docker-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

command_exists() {
  command -v "$1" &>/dev/null
}

check_compose_v1() {
  local compose_output
  local compose_status

  if ! command_exists docker-compose; then
    return 1
  fi

  set +e
  compose_output=$(docker-compose --version 2>&1)
  compose_status=$?
  set -e

  if [ "$compose_status" -eq 0 ]; then
    COMPOSE_V1_AVAILABLE=true
    log "✓ Docker Compose V1 available: $compose_output"
    return 0
  fi

  log "✗ Docker Compose V1 detected but failed to run"
  if echo "$compose_output" | grep -qi "No module named 'distutils'"; then
    log "Docker Compose V1 missing Python distutils module. Attempting install..."
    if apt_install python3-distutils || apt_install python3-setuptools; then
      if docker-compose --version >/dev/null 2>&1; then
        COMPOSE_V1_AVAILABLE=true
        log "✓ Docker Compose V1 available after installing Python modules"
        return 0
      fi
      log "✗ Docker Compose V1 still unavailable after installing Python modules"
    fi
  fi

  return 1
}

apt_install() {
  local package=$1
  local temp_log

  if ! command_exists apt-get; then
    log "apt-get not available, skipping install of ${package}"
    return 1
  fi

  temp_log=$(mktemp)
  if $SUDO apt-get update -qq && $SUDO apt-get install -y "$package" >/dev/null 2>"$temp_log"; then
    rm -f "$temp_log"
    return 0
  fi

  log "✗ Failed to install ${package} via apt-get"
  if [ -s "$temp_log" ]; then
    log "  apt-get error: $(tail -1 "$temp_log")"
  fi
  rm -f "$temp_log"
  return 1
}

SUDO=""
if command_exists sudo; then
  SUDO="sudo"
fi

log "Checking Docker availability..."

DOCKER_CLI_AVAILABLE=false
DOCKER_DAEMON_AVAILABLE=false
DOCKER_SOCKET_AVAILABLE=false
COMPOSE_V2_AVAILABLE=false
COMPOSE_V1_AVAILABLE=false

if command_exists docker; then
  DOCKER_CLI_AVAILABLE=true
  log "✓ Docker CLI found: $(docker --version 2>/dev/null)"
else
  log "✗ Docker CLI not found"
fi

if [ "$DOCKER_CLI_AVAILABLE" = false ]; then
  log "Installing Docker CLI..."
  if apt_install docker.io; then
    DOCKER_CLI_AVAILABLE=true
    log "✓ Docker CLI installed: $(docker --version 2>/dev/null)"
  fi
fi

if [ -S /var/run/docker.sock ]; then
  DOCKER_SOCKET_AVAILABLE=true
  log "✓ Docker socket found: /var/run/docker.sock"
else
  log "✗ Docker socket not found"
fi

if [ "$DOCKER_CLI_AVAILABLE" = true ]; then
  set +e
  DOCKER_INFO_OUTPUT=$(docker info 2>&1)
  DOCKER_INFO_STATUS=$?
  set -e

  if [ "$DOCKER_INFO_STATUS" -eq 0 ]; then
    DOCKER_DAEMON_AVAILABLE=true
    log "✓ Docker daemon is running"
  else
    log "✗ Cannot connect to Docker daemon"
    if echo "$DOCKER_INFO_OUTPUT" | grep -qi "permission denied"; then
      log "Docker permission denied. Attempting to add user to docker group..."
      if command_exists getent && getent group docker >/dev/null 2>&1; then
        if ! id -nG "${USER:-$(id -un)}" | tr ' ' '\n' | grep -qx docker; then
          if [ -n "$SUDO" ]; then
            if $SUDO usermod -aG docker "${USER:-$(id -un)}" 2>/dev/null; then
              log "✓ Added user to docker group (re-login required)"
            else
              log "✗ Failed to add user to docker group"
            fi
          else
            log "sudo not available, cannot modify docker group membership"
          fi
        fi
      else
        log "docker group not found"
      fi
    fi
  fi
fi

if [ "$DOCKER_CLI_AVAILABLE" = true ]; then
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_V2_AVAILABLE=true
    log "✓ Docker Compose V2 available: $(docker compose version --short 2>/dev/null)"
  else
    log "✗ Docker Compose V2 not available"
  fi
fi

if [ "$COMPOSE_V2_AVAILABLE" = false ] && command_exists docker-compose; then
  check_compose_v1 || true
fi

if [ "$COMPOSE_V2_AVAILABLE" = false ] && [ "$COMPOSE_V1_AVAILABLE" = false ]; then
  log "Installing Docker Compose plugin..."
  if apt_install docker-compose-plugin; then
    if docker compose version >/dev/null 2>&1; then
      COMPOSE_V2_AVAILABLE=true
      log "✓ Docker Compose V2 installed: $(docker compose version --short 2>/dev/null)"
    else
      log "✗ Docker Compose plugin installed but unavailable"
    fi
  fi

  if [ "$COMPOSE_V2_AVAILABLE" = false ]; then
    log "Attempting to install Docker Compose V1..."
    if apt_install docker-compose; then
      check_compose_v1 || true
    fi
  fi
fi

log ""
if [ "$DOCKER_CLI_AVAILABLE" = true ] && [ "$DOCKER_DAEMON_AVAILABLE" = true ]; then
  log "Docker is available in this environment."
  log "You can use the Dockerfile for environment setup:"
  log "  docker build -t dev-env ."
  log "  docker run --rm -v \$(pwd):/workspace dev-env <command>"
else
  log "Docker is NOT available in this environment."
  log "Please use env-setup.sh for environment setup instead:"
  log "  bash .codex/hooks/env-setup.sh"
fi

exit 0
