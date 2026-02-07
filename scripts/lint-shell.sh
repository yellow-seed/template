#!/bin/bash
set -e
echo "Running shellcheck..."
find . -name "*.sh" -type f -print0 | xargs -0 shellcheck --severity=warning
echo ""
echo "Running shfmt..."
find . -name "*.sh" -not -name "*.bats" -type f -print0 | xargs -0 shfmt -i 2 -d
echo ""
echo "All linting checks passed!"
