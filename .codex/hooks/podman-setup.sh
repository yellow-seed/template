#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p "${repo_root}/certs"
cp /usr/local/share/ca-certificates/envoy-mitmproxy-ca-cert.crt \
  "${repo_root}/certs/egress-proxy.crt"

cd "${repo_root}"
sudo podman build --isolation=chroot -f Dockerfile.podman .
