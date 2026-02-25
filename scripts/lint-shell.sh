#!/bin/bash
set -euo pipefail

if ! command -v qlty >/dev/null 2>&1; then
	echo "qlty not found, skipping lint checks"
	exit 0
fi

if [ "$#" -gt 0 ]; then
	qlty check "$@"
else
	qlty check --all
fi
