#!/usr/bin/env bash
set -euo pipefail

LOG_PREFIX="[gh-setup]"

log_info() {
	local message="$1"
	echo "${LOG_PREFIX} ${message}" >&2
}

install_gh_extension() {
	local gh_cmd="$1"
	local extension_repo="$2"
	local extension_name="${extension_repo#*/}"

	log_info "Checking ${extension_name} extension..."

	if "${gh_cmd}" extension list 2>/dev/null | grep -q "${extension_repo}"; then
		log_info "${extension_name} extension already installed"
		return 0
	fi

	log_info "Installing ${extension_name} extension..."
	if "${gh_cmd}" extension install "${extension_repo}" 2>/dev/null; then
		log_info "${extension_name} extension installed successfully"
	else
		log_info "Failed to install ${extension_name} extension (non-critical, continuing)"
	fi
}

install_gh_extensions() {
	local gh_cmd="$1"
	install_gh_extension "${gh_cmd}" "yahsan2/gh-sub-issue"
	install_gh_extension "${gh_cmd}" "harakeishi/gh-discussion"
}

if [[ -z ${REMOTE_ENV_VAR:-} ]]; then
	log_info "REMOTE_ENV_VAR is not set, skipping gh setup"
	exit 0
fi

REMOTE_ENV_VALUE="${!REMOTE_ENV_VAR:-}"
if [[ ${REMOTE_ENV_VALUE} != "true" ]]; then
	log_info "Not a remote session, skipping gh setup"
	exit 0
fi

log_info "Remote session detected, checking gh CLI..."

LOCAL_BIN="${HOME}/.local/bin"
mkdir -p "${LOCAL_BIN}"

if command -v gh &>/dev/null; then
	log_info "gh CLI already available: $(gh --version | head -1)"
	install_gh_extensions "gh"
	exit 0
fi

if [[ -x "${LOCAL_BIN}/gh" ]]; then
	log_info "gh found in ${LOCAL_BIN}"
	if [[ ":${PATH}:" != *":${LOCAL_BIN}:"* ]]; then
		export PATH="${LOCAL_BIN}:${PATH}"
		if [[ -n ${ENV_FILE:-} ]]; then
			echo "export PATH=\"${LOCAL_BIN}:\${PATH}\"" >>"${ENV_FILE}"
			log_info "PATH updated in ENV_FILE"
		fi
	fi
	install_gh_extensions "${LOCAL_BIN}/gh"
	exit 0
fi

log_info "Installing gh CLI to ${LOCAL_BIN}..."

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

ARCH="$(uname -m)"
case "${ARCH}" in
x86_64)
	GH_ARCH="amd64"
	;;
aarch64 | arm64)
	GH_ARCH="arm64"
	;;
*)
	log_info "Unsupported architecture: ${ARCH}"
	exit 0
	;;
esac

GH_VERSION="2.62.0"
GH_TARBALL="gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz"
GH_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}/${GH_TARBALL}"

log_info "Downloading gh v${GH_VERSION} for ${GH_ARCH}..."

if ! curl -sL "${GH_URL}" -o "${TEMP_DIR}/${GH_TARBALL}"; then
	log_info "Failed to download gh CLI"
	exit 0
fi

log_info "Extracting..."
if ! tar -xzf "${TEMP_DIR}/${GH_TARBALL}" -C "${TEMP_DIR}"; then
	log_info "Failed to extract gh CLI"
	exit 0
fi

if ! mv "${TEMP_DIR}/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh" "${LOCAL_BIN}/gh"; then
	log_info "Failed to install gh CLI"
	exit 0
fi

chmod +x "${LOCAL_BIN}/gh"

export PATH="${LOCAL_BIN}:${PATH}"

if [[ -n ${ENV_FILE:-} ]]; then
	echo "export PATH=\"${LOCAL_BIN}:\${PATH}\"" >>"${ENV_FILE}"
	log_info "PATH persisted to ENV_FILE"
fi

log_info "gh CLI installed successfully: $("${LOCAL_BIN}/gh" --version | head -1)"

install_gh_extensions "${LOCAL_BIN}/gh"

exit 0
