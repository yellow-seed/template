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
  "$REPO_ROOT/scripts/lint-shell.sh"
  checked=true
fi

# Use the same commands as CI (doc-lint.yml)
if "$has_docs"; then
  log "Running document checks..."
  if [ ! -x "$REPO_ROOT/node_modules/.bin/prettier" ]; then
    log "Prettier is not installed. Run 'npm ci' to install dependencies."
    exit 1
  fi
  npm run format:check
  checked=true
fi

# Use the same commands as CI (actionlint.yml)
if "$has_workflows"; then
  if ! command -v actionlint >/dev/null 2>&1; then
    log "actionlint is not installed. Please run scripts/install-tools.sh."
    exit 1
  fi
  log "Running actionlint..."
  actionlint
  checked=true
fi

if ! "$checked"; then
  log "No relevant files to lint."
fi
