#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

status=0

"$SCRIPT_DIR/lint-shell.sh" "$@" || status=$?
"$SCRIPT_DIR/lint-docs.sh" "$@" || status=$?

exit "$status"
