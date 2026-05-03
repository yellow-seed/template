#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
	export WORK_DIR
	WORK_DIR="$(mktemp -d)"
	export HOME="$WORK_DIR/home"
	mkdir -p "$HOME/.local/bin"

	mkdir -p "$WORK_DIR/scripts/installers"

	cp "$REPO_ROOT/scripts/install-tools.sh" "$WORK_DIR/scripts/install-tools.sh"
	cp "$REPO_ROOT/scripts/installers/_common.sh" "$WORK_DIR/scripts/installers/_common.sh"

	export CALL_LOG="$WORK_DIR/calls.log"
	: >"$CALL_LOG"

	# Stub mise.sh: records invocation and plants a fake mise binary in $HOME/.local/bin
	cat >"$WORK_DIR/scripts/installers/mise.sh" <<SCRIPT
#!/bin/bash
echo "mise.sh" >>"$CALL_LOG"
cat >"\$HOME/.local/bin/mise" <<'MISE'
#!/bin/bash
echo "mise \$*" >>"$CALL_LOG"
MISE
chmod +x "\$HOME/.local/bin/mise"
SCRIPT
	chmod +x "$WORK_DIR/scripts/installers/mise.sh"

	# Stub helper-scripts.sh
	cat >"$WORK_DIR/scripts/installers/helper-scripts.sh" <<SCRIPT
#!/bin/bash
echo "helper-scripts.sh" >>"$CALL_LOG"
SCRIPT
	chmod +x "$WORK_DIR/scripts/installers/helper-scripts.sh"

	export INSTALL_PREFIX="$WORK_DIR/bin"
	mkdir -p "$INSTALL_PREFIX"
}

teardown() {
	rm -rf "$WORK_DIR"
}

@test "install-tools invokes mise installer" {
	run bash "$WORK_DIR/scripts/install-tools.sh"
	[ "$status" -eq 0 ]

	run grep -x "mise.sh" "$CALL_LOG"
	[ "$status" -eq 0 ]
}

@test "install-tools runs mise install" {
	run bash "$WORK_DIR/scripts/install-tools.sh"
	[ "$status" -eq 0 ]

	run grep "^mise install" "$CALL_LOG"
	[ "$status" -eq 0 ]
}
