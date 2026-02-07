#!/bin/bash
set -euo pipefail

declare -a shell_files=()
declare -a shfmt_files=()

if [ "$#" -gt 0 ]; then
  for file in "$@"; do
    if [[ "$file" == *.sh ]]; then
      shell_files+=("$file")
      if [[ "$file" != *.bats ]]; then
        shfmt_files+=("$file")
      fi
    fi
  done
else
  while IFS= read -r -d '' file; do
    shell_files+=("$file")
    if [[ "$file" != *.bats ]]; then
      shfmt_files+=("$file")
    fi
  done < <(find . -name "*.sh" -type f -print0)
fi

if [ "${#shell_files[@]}" -eq 0 ]; then
  echo "No shell files to lint."
  exit 0
fi

echo "Running shellcheck..."
shellcheck --severity=warning "${shell_files[@]}"
echo ""

if [ "${#shfmt_files[@]}" -gt 0 ]; then
  echo "Running shfmt..."
  shfmt -i 2 -d "${shfmt_files[@]}"
  echo ""
fi

echo "All linting checks passed!"
