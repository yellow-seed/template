#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[bootstrap-gh]"

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

log_error() {
	local message="$1"
	echo "${LOG_PREFIX} ERROR: ${message}" >&2
}

INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "${INSTALL_DIR}"

if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
	export PATH="${INSTALL_DIR}:${PATH}"
fi

if command -v gh >/dev/null 2>&1; then
	log_info "gh already available: $(gh --version 2>&1 | head -1)"
	exit 0
fi

log_info "Fetching latest gh CLI release..."

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "${ARCH}" in
x86_64) ARCH="amd64" ;;
aarch64 | arm64) ARCH="arm64" ;;
*)
	log_error "Unsupported architecture: ${ARCH}"
	exit 1
	;;
esac

VERSION="$(curl -sfLS "https://api.github.com/repos/cli/cli/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
if [[ -z ${VERSION} ]]; then
	log_error "Failed to fetch latest gh version"
	exit 1
fi

log_info "Downloading gh v${VERSION} (${OS}/${ARCH})..."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

ARCHIVE="gh_${VERSION}_${OS}_${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/cli/cli/releases/download/v${VERSION}/${ARCHIVE}"

if ! curl -sfLS "${DOWNLOAD_URL}" -o "${TMP_DIR}/${ARCHIVE}"; then
	log_error "Failed to download gh from ${DOWNLOAD_URL}"
	exit 1
fi

tar -xzf "${TMP_DIR}/${ARCHIVE}" -C "${TMP_DIR}"
cp "${TMP_DIR}/gh_${VERSION}_${OS}_${ARCH}/bin/gh" "${INSTALL_DIR}/gh"
chmod +x "${INSTALL_DIR}/gh"

if command -v gh >/dev/null 2>&1; then
	log_info "gh installed: $(gh --version 2>&1 | head -1)"
else
	log_error "gh not found after install"
	exit 1
fi
