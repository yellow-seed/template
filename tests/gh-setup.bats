#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/gh-setup.sh"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  export GH_LOG="$WORK_DIR/gh.log"
  export GH_EXTENSIONS="$WORK_DIR/extensions.txt"
  : >"$GH_LOG"
  : >"$GH_EXTENSIONS"

  mkdir -p "$WORK_DIR/bin"
  cat >"$WORK_DIR/bin/gh" <<'GH'
#!/bin/bash
set -e

printf '%s\n' "$*" >>"$GH_LOG"

case "$1 $2" in
  "--version ")
    echo "gh version 9.9.9"
    ;;
  "extension list")
    cat "$GH_EXTENSIONS"
    ;;
  "extension install")
    echo "$3" >>"$GH_EXTENSIONS"
    ;;
esac
GH
  chmod +x "$WORK_DIR/bin/gh"

  export PATH="$WORK_DIR/bin:$PATH"
  export REMOTE_ENV_VAR="TEST_REMOTE"
  export TEST_REMOTE=true

  export TEST_REPO="$WORK_DIR/repo"
  mkdir -p "$TEST_REPO"
  git init "$TEST_REPO" >/dev/null
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "gh-setup installs gh-sub-issue and gh-discussion extensions" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run grep -x "yahsan2/gh-sub-issue" "$GH_EXTENSIONS"
  [ "$status" -eq 0 ]

  run grep -x "harakeishi/gh-discussion" "$GH_EXTENSIONS"
  [ "$status" -eq 0 ]
}

@test "gh-setup skips extension install when both extensions already exist" {
  cat >"$GH_EXTENSIONS" <<'EXT'
yahsan2/gh-sub-issue
harakeishi/gh-discussion
EXT

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run awk '/^extension install / { count++ } END { print count + 0 }' "$GH_LOG"
  [ "$status" -eq 0 ]
  [ "$output" -eq 0 ]
}

@test "gh-setup configures origin from GITHUB_REPOSITORY when missing" {
  cd "$TEST_REPO"
  export GITHUB_REPOSITORY="yellow-seed/template"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run git remote get-url origin
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/yellow-seed/template.git" ]
}

@test "gh-setup does not overwrite existing origin" {
  cd "$TEST_REPO"
  git remote add origin "https://example.com/custom/repo.git"
  export GITHUB_REPOSITORY="yellow-seed/template"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run git remote get-url origin
  [ "$status" -eq 0 ]
  [ "$output" = "https://example.com/custom/repo.git" ]
}

@test "gh-setup uses custom remote base URL when provided" {
  cd "$TEST_REPO"
  export GITHUB_REPOSITORY="yellow-seed/template"
  export GITHUB_REMOTE_URL_BASE="https://proxy.local/github"

  run bash "$SCRIPT"
  [ "$status" -eq 0 ]

  run git remote get-url origin
  [ "$status" -eq 0 ]
  [ "$output" = "https://proxy.local/github/yellow-seed/template.git" ]
}
