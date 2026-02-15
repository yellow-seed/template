#!/bin/bash
set -euo pipefail

declare -a markdown_files=()
declare -a yaml_files=()
declare -a json_files=()
prettier_cmd=(npx --no-install prettier)

if [ ! -x "node_modules/.bin/prettier" ]; then
  echo "Prettier is not installed. Run 'npm ci' to install dependencies." >&2
  exit 1
fi

matches_markdown() {
  local file="$1"
  [[ "$file" == "README.md" ]] ||
    [[ "$file" == "AGENTS.md" ]] ||
    [[ "$file" == "CLAUDE.md" ]] ||
    [[ "$file" == docs/*.md ]] ||
    [[ "$file" == docs/**/*.md ]] ||
    [[ "$file" == .github/*.md ]] ||
    [[ "$file" == .github/**/*.md ]]
}

is_excluded_markdown() {
  local file="$1"
  [[ "$file" == .github/skills/* ]] || [[ "$file" == .github/skills/**/* ]]
}

matches_yaml() {
  local file="$1"
  [[ "$file" == "compose.yml" ]] ||
    [[ "$file" == "codecov.yml" ]] ||
    [[ "$file" == .github/*.yml ]] ||
    [[ "$file" == .github/**/*.yml ]] ||
    [[ "$file" == .github/*.yaml ]] ||
    [[ "$file" == .github/**/*.yaml ]]
}

matches_json() {
  local file="$1"
  [[ "$file" == .github/*.json ]] || [[ "$file" == .github/**/*.json ]]
}

if [ "$#" -gt 0 ]; then
  for file in "$@"; do
    if matches_markdown "$file" && ! is_excluded_markdown "$file"; then
      markdown_files+=("$file")
    fi
    if matches_yaml "$file"; then
      yaml_files+=("$file")
    fi
    if matches_json "$file"; then
      json_files+=("$file")
    fi
  done
else
  markdown_files=("README.md" "AGENTS.md" "CLAUDE.md" "docs/**/*.md" ".github/**/*.md")
  yaml_files=("compose.yml" "codecov.yml" ".github/**/*.{yml,yaml}")
  json_files=(".github/**/*.json")
fi

if [ "${#markdown_files[@]}" -eq 0 ] &&
  [ "${#yaml_files[@]}" -eq 0 ] &&
  [ "${#json_files[@]}" -eq 0 ]; then
  echo "No document files to lint."
  exit 0
fi

if [ "$#" -gt 0 ]; then
  declare -a doc_files=("${markdown_files[@]}" "${yaml_files[@]}" "${json_files[@]}")
  echo "Running Prettier for changed document files..."
  "${prettier_cmd[@]}" --check "${doc_files[@]}"
else
  echo "Running npm run format:check..."
  npm run format:check
fi

echo "All document linting checks passed!"
