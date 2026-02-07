#!/bin/bash
set -e
echo "Running Prettier (Markdown)..."
prettier --check "README.md" "AGENTS.md" "CLAUDE.md" "docs/**/*.md" ".github/**/*.md"
echo ""
echo "Running Prettier (YAML)..."
prettier --check "compose.yml" "codecov.yml" ".github/**/*.{yml,yaml}"
echo ""
echo "Running Prettier (JSON)..."
prettier --check ".github/**/*.json"
echo ""
echo "All document linting checks passed!"
