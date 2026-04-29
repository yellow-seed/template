#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/env-setup.sh"

setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  mkdir -p "$WORK_DIR/repo/scripts" "$WORK_DIR/bin"
  cp "$SCRIPT" "$WORK_DIR/repo/scripts/env-setup.sh"

  # install-tools.sh stub (tools are already mocked in PATH)
  printf '#!/bin/bash\nexit 0\n' >"$WORK_DIR/repo/scripts/install-tools.sh"
  chmod +x "$WORK_DIR/repo/scripts/install-tools.sh"

  cat >"$WORK_DIR/bin/dotenvx" <<'DOTENVX'
#!/bin/bash
set -euo pipefail

if [ "$1" != "run" ] || [ "$2" != "-f" ] || [ "$3" != ".env.remote" ] || [ "$4" != "--" ]; then
  printf 'unexpected dotenvx args: %s\n' "$*" >&2
  exit 2
fi

shift 4
GH_TOKEN="remote-token" EXTRA_SECRET="hidden" "$@"
DOTENVX
  chmod +x "$WORK_DIR/bin/dotenvx"

  export PATH="$WORK_DIR/bin:$PATH"
  export DOTENV_PRIVATE_KEY_REMOTE="test-key"
}

teardown() {
  rm -rf "$WORK_DIR"
}

@test "env-setup decrypts .env.remote into a private root .env with only GH_TOKEN" {
  touch "$WORK_DIR/repo/.env.remote"

  run bash "$WORK_DIR/repo/scripts/env-setup.sh"
  [ "$status" -eq 0 ]

  run cat "$WORK_DIR/repo/.env"
  [ "$status" -eq 0 ]
  [ "$output" = "GH_TOKEN=remote-token" ]

  run grep -q "EXTRA_SECRET" "$WORK_DIR/repo/.env"
  [ "$status" -eq 1 ]

  if stat -c "%a" "$WORK_DIR/repo/.env" >/dev/null 2>&1; then
    mode="$(stat -c "%a" "$WORK_DIR/repo/.env")"
  else
    mode="$(stat -f "%Lp" "$WORK_DIR/repo/.env")"
  fi
  [ "$mode" = "600" ]
}

@test "env-setup skips env decryption when .env.remote is missing" {
  run bash "$WORK_DIR/repo/scripts/env-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *".env.remote not found"* ]]
}

@test "env-setup skips env decryption when DOTENV_PRIVATE_KEY_REMOTE is not set" {
  touch "$WORK_DIR/repo/.env.remote"
  unset DOTENV_PRIVATE_KEY_REMOTE

  run bash "$WORK_DIR/repo/scripts/env-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DOTENV_PRIVATE_KEY_REMOTE not set"* ]]
}
