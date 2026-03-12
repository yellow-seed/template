#!/bin/bash
set -u
set -o pipefail

ORCHESTRATOR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$ORCHESTRATOR_DIR/installers/_common.sh"

SKIP_INSTALLERS="${SKIP_INSTALLERS:-}"

run_step() {
	local name="$1"
	local command="$2"

	if ! eval "$command"; then
		had_failure=true
		fail "Installer failed: $name"
		if [ "$STRICT_MODE" != "true" ]; then
			log "Continuing after failure because STRICT_MODE=$STRICT_MODE"
		fi
	fi
}

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
	local installers=(
		mise
		bats
		dotenvx
		qlty
		terraform
	)
	local mise_managed_installers=(
		bats
		dotenvx
		terraform
	)
	local apt_stamp_dir
	local installer
	local use_mise=false
	had_failure=false

	apt_stamp_dir=$(mktemp -d)
	APT_UPDATE_STAMP="$apt_stamp_dir/apt-update.stamp"
	export APT_UPDATE_STAMP
	trap 'rm -rf "${APT_UPDATE_STAMP%/*}"' EXIT

	log "Starting tool installation"
	ensure_path

	if should_skip "mise"; then
		log "Skipping mise (SKIP_INSTALLERS)"
	elif command_exists mise; then
		log "mise is available; using mise-managed installation flow"
		use_mise=true
	else
		run_step "mise" "bash '$ORCHESTRATOR_DIR/installers/mise.sh'"
		if command_exists mise; then
			log "mise became available; using mise-managed installation flow"
			use_mise=true
		fi
	fi

	if [ "$use_mise" = "true" ]; then
		run_step "mise install" "mise install"
	fi

	for installer in "${installers[@]}"; do
		if [ "$installer" = "mise" ]; then
			continue
		fi

		if should_skip "$installer"; then
			log "Skipping $installer (SKIP_INSTALLERS)"
			continue
		fi

		if [ "$use_mise" = "true" ] && [[ " ${mise_managed_installers[*]} " == *" $installer "* ]]; then
			log "Skipping $installer (managed by mise)"
			continue
		fi

		run_step "$installer" "bash '$ORCHESTRATOR_DIR/installers/${installer}.sh'"
	done

	if [ "$had_failure" = "true" ]; then
		log "Tool installation completed with errors"
		return 1
	fi

	log "Tool installation completed"
}

main "$@"
