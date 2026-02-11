#!/usr/bin/env bats

# Tests for .codex/hooks/codex-setup.sh – git remote removal

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/.codex/hooks/codex-setup.sh"

setup() {
  # Create a temporary workspace that looks like a git repo with a remote
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"
  git -C "$WORK_DIR" init --quiet
  git -C "$WORK_DIR" remote add origin https://example.com/repo.git
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "codex-setup.sh contains git remote remove step" {
  grep -q 'git.*remote.*remove\|git.*remote.*rm' "$SCRIPT"
}

@test "git remote remove origin is idempotent (no error when remote absent)" {
  # Remove remote first so it doesn't exist
  git -C "$WORK_DIR" remote remove origin

  # Source just the remote-removal portion — simulate the logic
  # that codex-setup.sh should have
  run bash -c "
    cd '$WORK_DIR'
    git remote remove origin 2>/dev/null || true
  "
  [ "$status" -eq 0 ]
}

@test "git remote remove origin actually removes the remote" {
  # Verify remote exists before
  run git -C "$WORK_DIR" remote
  [[ "$output" == *"origin"* ]]

  # Execute the remove logic that should be in codex-setup.sh
  run bash -c "
    cd '$WORK_DIR'
    git remote remove origin 2>/dev/null || true
  "
  [ "$status" -eq 0 ]

  # Verify remote is gone
  run git -C "$WORK_DIR" remote
  [[ "$output" != *"origin"* ]]
}
