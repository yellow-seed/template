#!/bin/bash
# Common GitHub CLI setup script for remote environments
# This script installs gh CLI and required gh extensions when running remotely.

set -e

LOG_PREFIX="[gh-setup]"

log() {
	echo "$LOG_PREFIX $1" >&2
}

install_gh_extension() {
	local gh_cmd="$1"
	local extension_repo="$2"
	local extension_name="${extension_repo#*/}"

	log "Checking ${extension_name} extension..."

	if "$gh_cmd" extension list 2>/dev/null | grep -q "$extension_repo"; then
		log "${extension_name} extension already installed"
		return 0
	fi

	log "Installing ${extension_name} extension..."
	if "$gh_cmd" extension install "$extension_repo" 2>/dev/null; then
		log "${extension_name} extension installed successfully"
	else
		log "Failed to install ${extension_name} extension (non-critical, continuing)"
	fi
}

install_gh_extensions() {
	local gh_cmd="$1"

	install_gh_extension "$gh_cmd" "yahsan2/gh-sub-issue"
	install_gh_extension "$gh_cmd" "harakeishi/gh-discussion"
}

extract_repo_slug() {
	local value="$1"

	if [ -z "$value" ]; then
		return 1
	fi

	value="${value#git@}"
	value="${value#ssh://git@}"
	value="${value#https://}"
	value="${value#http://}"
	value="${value#*/}"
	value="${value#*:}"
	value="${value%.git}"

	if [[ "$value" =~ ^[^/]+/[^/]+$ ]]; then
		echo "$value"
		return 0
	fi

	return 1
}

resolve_repository_slug() {
	local repository="${GITHUB_REPOSITORY:-}"

	if [ -n "$repository" ]; then
		echo "$repository"
		return 0
	fi

	if repository=$(git config --get remote.upstream.url 2>/dev/null); then
		extract_repo_slug "$repository" && return 0
	fi

	if repository=$(git config --get github.repository 2>/dev/null); then
		extract_repo_slug "$repository" && return 0
	fi

	return 1
}

resolve_remote_base_url() {
	if [ -n "${GITHUB_REMOTE_URL_BASE:-}" ]; then
		echo "${GITHUB_REMOTE_URL_BASE%/}"
		return 0
	fi

	if [ -n "${GITHUB_SERVER_URL:-}" ]; then
		echo "${GITHUB_SERVER_URL%/}"
		return 0
	fi

	echo "https://github.com"
}

ensure_origin_remote() {
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		log "Not in a git repository, skipping origin remote setup"
		return 0
	fi

	if git remote get-url origin >/dev/null 2>&1; then
		log "origin remote already configured, skipping"
		return 0
	fi

	local repository
	if ! repository=$(resolve_repository_slug); then
		log "Could not resolve repository slug, skipping origin remote setup"
		return 0
	fi

	local base_url
	base_url=$(resolve_remote_base_url)
	local origin_url="${base_url}/${repository}.git"

	if git remote add origin "$origin_url"; then
		log "Configured origin remote: $origin_url"
	else
		log "Failed to configure origin remote (non-critical, continuing)"
	fi
}

if [ -z "${REMOTE_ENV_VAR:-}" ]; then
	log "REMOTE_ENV_VAR is not set, skipping gh setup"
	exit 0
fi

REMOTE_ENV_VALUE="${!REMOTE_ENV_VAR:-}"
if [ "$REMOTE_ENV_VALUE" != "true" ]; then
	log "Not a remote session, skipping gh setup"
	exit 0
fi

ensure_origin_remote

log "Remote session detected, checking gh CLI..."

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

if command -v gh &>/dev/null; then
	log "gh CLI already available: $(gh --version | head -1)"
	install_gh_extensions "gh"
	exit 0
fi

if [ -x "$LOCAL_BIN/gh" ]; then
	log "gh found in $LOCAL_BIN"
	if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
		export PATH="$LOCAL_BIN:$PATH"
		if [ -n "${ENV_FILE:-}" ]; then
			echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$ENV_FILE"
			log "PATH updated in ENV_FILE"
		fi
	fi
	install_gh_extensions "$LOCAL_BIN/gh"
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

if [ -n "${ENV_FILE:-}" ]; then
	echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >>"$ENV_FILE"
	log "PATH persisted to ENV_FILE"
fi

log "gh CLI installed successfully: $("$LOCAL_BIN/gh" --version | head -1)"

install_gh_extensions "$LOCAL_BIN/gh"

exit 0
