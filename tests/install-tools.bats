#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

@test "install-tools orchestrator includes qlty installer" {
  run grep -n 'install-qlty' "$REPO_ROOT/scripts/install-tools.sh"
  [ "$status" -eq 0 ]
}

@test "qlty installer script exists and is executable" {
  [ -x "$REPO_ROOT/scripts/installers/install-qlty.sh" ]
}
