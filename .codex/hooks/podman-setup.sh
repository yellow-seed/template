#!/usr/bin/env bash
# Codex hook: Podman environment setup for remote environments
# This script sets up Podman and builds the development container
# following best practices: idempotent, fail-safe, proper logging

set -euo pipefail

LOG_PREFIX="[podman-setup]"

log() {
  echo "$LOG_PREFIX $1" >&2
}

# Only run in remote Codex environment
if [ "${CODEX_REMOTE:-}" != "true" ]; then
  log "Not a remote Codex session (CODEX_REMOTE != true), skipping podman setup"
  exit 0
fi

log "Remote Codex session detected (CODEX_REMOTE=true), setting up Podman environment..."

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Install podman if not available
if ! command -v podman &>/dev/null; then
  log "Installing podman..."
  sudo apt-get update
  sudo apt-get install -y podman
else
  log "Podman already installed: $(podman --version)"
fi

# Copy proxy certificate for container builds
log "Setting up proxy certificate..."
mkdir -p "${repo_root}/certs"
if [ -f /usr/local/share/ca-certificates/envoy-mitmproxy-ca-cert.crt ]; then
  cp /usr/local/share/ca-certificates/envoy-mitmproxy-ca-cert.crt \
    "${repo_root}/certs/egress-proxy.crt"
  log "Proxy certificate copied to certs/egress-proxy.crt"
else
  log "Warning: Proxy certificate not found at expected location"
fi

# Build container using unified Dockerfile with REMOTE_ENV=true
log "Building development container with Podman..."
cd "${repo_root}"
sudo podman build \
  --build-arg CODEX_REMOTE=true \
  --isolation=chroot \
  -t dev-env \
  .

log "Podman setup completed successfully"
