#!/bin/bash
set -u
set -o pipefail

ORCHESTRATOR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$ORCHESTRATOR_DIR/installers/_common.sh"

SKIP_INSTALLERS="${SKIP_INSTALLERS:-}"

should_skip() {
	local name="$1"
	local token

	IFS=',' read -r -a skip_items <<<"$SKIP_INSTALLERS"
	for token in "${skip_items[@]}"; do
		token=$(trim "$token")
		if [ "$token" = "$name" ]; then
			return 0
		fi
	done

	return 1
}

main() {
	local mise_managed_installers=(
		bats
		dotenvx
		terraform
	)
	local apt_stamp_dir
	local had_failure=false
	local installer

	apt_stamp_dir=$(mktemp -d)
	APT_UPDATE_STAMP="$apt_stamp_dir/apt-update.stamp"
	export APT_UPDATE_STAMP
	trap 'rm -rf "${APT_UPDATE_STAMP%/*}"' EXIT

	log "Starting tool installation"
	ensure_path

	if should_skip "mise"; then
		log "Skipping mise install (SKIP_INSTALLERS)"
	else
		if ! bash "$ORCHESTRATOR_DIR/installers/mise.sh"; then
			had_failure=true
			fail "Installer failed: mise"
			if [ "$STRICT_MODE" != "true" ]; then
				log "Continuing after failure because STRICT_MODE=$STRICT_MODE"
			fi
		fi

		log "Running mise install"
		if ! mise install; then
			had_failure=true
			fail "mise install failed"
			if [ "$STRICT_MODE" != "true" ]; then
				log "Continuing after failure because STRICT_MODE=$STRICT_MODE"
			fi
		fi
	fi

	for installer in "${mise_managed_installers[@]}"; do
		if should_skip "$installer"; then
			log "Skipping $installer (SKIP_INSTALLERS)"
			continue
		fi
		if ! command_exists "$installer"; then
			log "Falling back to individual installer for $installer (not found after mise install)"
			if ! bash "$ORCHESTRATOR_DIR/installers/${installer}.sh"; then
				had_failure=true
				fail "Installer failed: $installer"
				if [ "$STRICT_MODE" != "true" ]; then
					log "Continuing after failure because STRICT_MODE=$STRICT_MODE"
				fi
			fi
		fi
	done

	if should_skip "qlty"; then
		log "Skipping qlty (SKIP_INSTALLERS)"
	else
		if ! bash "$ORCHESTRATOR_DIR/installers/qlty.sh"; then
			had_failure=true
			fail "Installer failed: qlty"
			if [ "$STRICT_MODE" != "true" ]; then
				log "Continuing after failure because STRICT_MODE=$STRICT_MODE"
			fi
		fi
	fi

	if [ "$had_failure" = "true" ]; then
		log "Tool installation completed with errors"
		return 1
	fi

	log "Tool installation completed"
}

main "$@"
