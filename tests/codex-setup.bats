#!/usr/bin/env bats

# Tests for .codex/hooks/codex-setup.sh – git remote removal

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/.codex/hooks/codex-setup.sh"

setup() {
  # Create a temporary workspace that mimics the repo directory structure
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  mkdir -p "$WORK_DIR/.codex/hooks"
  mkdir -p "$WORK_DIR/.claude/hooks"
  mkdir -p "$WORK_DIR/scripts"

  # Copy the actual script under test
  cp "$SCRIPT" "$WORK_DIR/.codex/hooks/codex-setup.sh"

  # Create no-op stubs for the other hooks so codex-setup.sh can run end-to-end
  for stub in \
    "$WORK_DIR/.codex/hooks/gh-setup.sh" \
    "$WORK_DIR/.codex/hooks/env-setup.sh" \
    "$WORK_DIR/.claude/hooks/skills-setup.sh" \
    "$WORK_DIR/scripts/setup-git-hooks.sh"; do
    printf '#!/bin/bash\nexit 0\n' >"$stub"
    chmod +x "$stub"
  done

  # Initialise a git repo with an origin remote
  git -C "$WORK_DIR" init --quiet
  git -C "$WORK_DIR" remote add origin https://example.com/repo.git
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "codex-setup.sh contains CODEX_REMOTE-guarded git remote remove step" {
  grep -q 'CODEX_REMOTE' "$SCRIPT"
  grep -q 'git -C "\$REPO_ROOT" remote remove origin' "$SCRIPT"
}

@test "codex-setup.sh removes origin when CODEX_REMOTE=true" {
  # Verify remote exists before
  run git -C "$WORK_DIR" remote
  [[ "$output" == *"origin"* ]]

  # Run the actual script with CODEX_REMOTE=true
  export CODEX_REMOTE=true
  run bash "$WORK_DIR/.codex/hooks/codex-setup.sh"
  [ "$status" -eq 0 ]

  # Verify remote is gone
  run git -C "$WORK_DIR" remote
  [[ "$output" != *"origin"* ]]
}

@test "codex-setup.sh preserves origin when CODEX_REMOTE is not set" {
  # Verify remote exists before
  run git -C "$WORK_DIR" remote
  [[ "$output" == *"origin"* ]]

  # Run the actual script without CODEX_REMOTE
  unset CODEX_REMOTE
  run bash "$WORK_DIR/.codex/hooks/codex-setup.sh"
  [ "$status" -eq 0 ]

  # Verify remote still exists
  run git -C "$WORK_DIR" remote
  [[ "$output" == *"origin"* ]]
}

@test "codex-setup.sh is idempotent when origin is already absent" {
  # Remove remote first
  git -C "$WORK_DIR" remote remove origin

  # Run the actual script – should not error
  export CODEX_REMOTE=true
  run bash "$WORK_DIR/.codex/hooks/codex-setup.sh"
  [ "$status" -eq 0 ]
}
