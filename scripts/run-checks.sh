#!/bin/bash
set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

"$SCRIPT_DIR/lint-shell.sh" "$@"
"$SCRIPT_DIR/lint-docs.sh" "$@"
