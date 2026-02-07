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

declare -a files=()
for file in "$@"; do
  if [ -z "$file" ]; then
    continue
  fi
  duplicate=false
  for existing in "${files[@]}"; do
    if [ "$existing" = "$file" ]; then
      duplicate=true
      break
    fi
  done
  if [ "$duplicate" = false ]; then
    files+=("$file")
  fi
done

declare -a shell_files=()
declare -a doc_files=()
declare -a workflow_files=()

for file in "${files[@]}"; do
  if [[ "$file" == *.sh ]]; then
    shell_files+=("$file")
  fi

  if [[ "$file" == "README.md" ]] ||
    [[ "$file" == "AGENTS.md" ]] ||
    [[ "$file" == "CLAUDE.md" ]] ||
    [[ "$file" == docs/*.md ]] ||
    [[ "$file" == docs/*/*.md ]] ||
    [[ "$file" == .github/*.md ]] ||
    [[ "$file" == .github/*/*.md ]] ||
    [[ "$file" == "compose.yml" ]] ||
    [[ "$file" == "codecov.yml" ]] ||
    [[ "$file" == .github/*.yml ]] ||
    [[ "$file" == .github/*/*.yml ]] ||
    [[ "$file" == .github/*.yaml ]] ||
    [[ "$file" == .github/*/*.yaml ]] ||
    [[ "$file" == .github/*.json ]] ||
    [[ "$file" == .github/*/*.json ]]; then
    doc_files+=("$file")
  fi

  if [[ "$file" == .github/workflows/*.yml ]] ||
    [[ "$file" == .github/workflows/*.yaml ]] ||
    [[ "$file" == .github/workflows/*/*.yml ]] ||
    [[ "$file" == .github/workflows/*/*.yaml ]]; then
    workflow_files+=("$file")
  fi
done

if [ "${#shell_files[@]}" -gt 0 ]; then
  log "Running shell checks..."
  "$REPO_ROOT/scripts/lint-shell.sh" "${shell_files[@]}"
fi

if [ "${#doc_files[@]}" -gt 0 ]; then
  log "Running document checks..."
  "$REPO_ROOT/scripts/lint-docs.sh" "${doc_files[@]}"
fi

if [ "${#workflow_files[@]}" -gt 0 ]; then
  if ! command -v actionlint >/dev/null 2>&1; then
    log "actionlint is not installed. Please run scripts/install-tools.sh."
    exit 1
  fi
  log "Running actionlint..."
  actionlint "${workflow_files[@]}"
fi

if [ "${#shell_files[@]}" -eq 0 ] &&
  [ "${#doc_files[@]}" -eq 0 ] &&
  [ "${#workflow_files[@]}" -eq 0 ]; then
  log "No relevant files to lint."
fi
