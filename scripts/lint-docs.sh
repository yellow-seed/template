#!/bin/bash
set -euo pipefail

declare -a markdown_files=()
declare -a yaml_files=()
declare -a json_files=()
prettier_cmd=(npx --no-install prettier)

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
    if matches_markdown "$file"; then
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

if [ "${#markdown_files[@]}" -gt 0 ]; then
  echo "Running Prettier (Markdown)..."
  "${prettier_cmd[@]}" --check "${markdown_files[@]}"
  echo ""
fi

if [ "${#yaml_files[@]}" -gt 0 ]; then
  echo "Running Prettier (YAML)..."
  "${prettier_cmd[@]}" --check "${yaml_files[@]}"
  echo ""
fi

if [ "${#json_files[@]}" -gt 0 ]; then
  echo "Running Prettier (JSON)..."
  "${prettier_cmd[@]}" --check "${json_files[@]}"
  echo ""
fi

if [ "${#markdown_files[@]}" -eq 0 ] &&
  [ "${#yaml_files[@]}" -eq 0 ] &&
  [ "${#json_files[@]}" -eq 0 ]; then
  echo "No document files to lint."
  exit 0
fi

echo "All document linting checks passed!"
