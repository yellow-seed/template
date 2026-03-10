#!/bin/bash
set -euo pipefail

if ! command -v qlty >/dev/null 2>&1 && [ -x "$HOME/.qlty/bin/qlty" ]; then
	export PATH="$HOME/.qlty/bin:$PATH"
fi

if ! command -v qlty >/dev/null 2>&1; then
	echo "[run-checks] Error: qlty is not installed or not in PATH" >&2
	echo "[run-checks] Install with: bash scripts/installers/qlty.sh" >&2
	exit 1
fi

exec qlty check --all "$@"
