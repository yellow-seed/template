#!/bin/bash
set -euo pipefail

if ! command -v actionlint >/dev/null 2>&1; then
  echo "actionlint is not installed. Please run scripts/install-tools.sh." >&2
  exit 1
fi

declare -a workflow_files=()

if [ "$#" -gt 0 ]; then
  for file in "$@"; do
    if [[ "$file" == .github/workflows/* ]]; then
      workflow_files+=("$file")
    fi
  done
fi

if [ "${#workflow_files[@]}" -gt 0 ]; then
  echo "Running actionlint for changed workflow files..."
  actionlint "${workflow_files[@]}"
else
  echo "Running actionlint..."
  actionlint
fi

echo "Actionlint checks passed!"
