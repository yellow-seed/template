#!/bin/bash
set -euo pipefail

LOG_PREFIX="[githooks]"

log() {
  echo "$LOG_PREFIX $*" >&2
}

if ! REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  log "Not inside a git repository."
  exit 0
fi

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ "${CODEX_REMOTE:-}" != "true" ]; then
  log "AI hooks disabled (not in Claude/Codex remote environment)."
  exit 0
fi

cd "$REPO_ROOT"

if [ "$#" -eq 0 ]; then
  log "No files provided for linting."
  exit 0
fi

# Detect which categories of files changed
has_shell=false
has_docs=false
has_workflows=false

for file in "$@"; do
  case "$file" in
  *.sh) has_shell=true ;;
  esac
  case "$file" in
  *.md | *.yml | *.yaml | *.json) has_docs=true ;;
  esac
  case "$file" in
  .github/workflows/*) has_workflows=true ;;
  esac
done

checked=false

# Use the same commands as CI (ci.yml)
if "$has_shell"; then
  log "Running shell checks..."
  "$REPO_ROOT/scripts/lint-shell.sh" "$@"
  checked=true
fi

# Use the same commands as CI (doc-lint.yml)
if "$has_docs"; then
  log "Running document checks..."
  "$REPO_ROOT/scripts/lint-docs.sh" "$@"
  checked=true
fi

# Use the same commands as CI (actionlint.yml)
if "$has_workflows"; then
  log "Running actionlint..."
  "$REPO_ROOT/scripts/lint-actions.sh" "$@"
  checked=true
fi

if ! "$checked"; then
  log "No relevant files to lint."
fi
