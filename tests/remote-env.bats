#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# --- shared dotenvx stub factory ---

make_dotenvx_stub() {
  local bin_dir="$1"
  cat >"$bin_dir/dotenvx" <<'DOTENVX'
#!/bin/bash
set -euo pipefail

if [ "$1" != "run" ] || [ "$2" != "-f" ] || [ "$3" != ".env.remote" ] || [ "$4" != "--" ]; then
  printf 'unexpected dotenvx args: %s\n' "$*" >&2
  exit 2
fi

shift 4
GH_TOKEN="remote-token" EXTRA_SECRET="hidden" "$@"
DOTENVX
  chmod +x "$bin_dir/dotenvx"
}

# =====================================================================
# scripts/env-setup.sh
# =====================================================================

SCRIPT_ENV_SETUP="$REPO_ROOT/scripts/env-setup.sh"

setup_env_setup() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  mkdir -p "$WORK_DIR/repo/scripts" "$WORK_DIR/bin"
  cp "$SCRIPT_ENV_SETUP" "$WORK_DIR/repo/scripts/env-setup.sh"

  printf '#!/bin/bash\nexit 0\n' >"$WORK_DIR/repo/scripts/install-tools.sh"
  chmod +x "$WORK_DIR/repo/scripts/install-tools.sh"

  make_dotenvx_stub "$WORK_DIR/bin"

  export PATH="$WORK_DIR/bin:$PATH"
  export DOTENV_PRIVATE_KEY_REMOTE="test-key"
}

teardown_env_setup() {
  rm -rf "$WORK_DIR"
}

@test "env-setup decrypts .env.remote into a private root .env with only GH_TOKEN" {
  setup_env_setup
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

  teardown_env_setup
}

@test "env-setup skips env decryption when .env.remote is missing" {
  setup_env_setup

  run bash "$WORK_DIR/repo/scripts/env-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *".env.remote not found"* ]]

  teardown_env_setup
}

@test "env-setup skips env decryption when DOTENV_PRIVATE_KEY_REMOTE is not set" {
  setup_env_setup
  touch "$WORK_DIR/repo/.env.remote"
  unset DOTENV_PRIVATE_KEY_REMOTE

  run bash "$WORK_DIR/repo/scripts/env-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DOTENV_PRIVATE_KEY_REMOTE not set"* ]]

  teardown_env_setup
}

# =====================================================================
# scripts/setup-remote-env.sh
# =====================================================================

SCRIPT_REMOTE_ENV="$REPO_ROOT/.codex/hooks/setup-remote-env.sh"

setup_remote_env() {
  export WORK_DIR
  WORK_DIR="$(mktemp -d)"

  export HOME="$WORK_DIR/home"
  mkdir -p "$HOME/.local/bin"

  mkdir -p "$WORK_DIR/repo/scripts" "$WORK_DIR/bin"
  mkdir -p "$WORK_DIR/repo/.codex/hooks"
  cp "$SCRIPT_REMOTE_ENV" "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"

  make_dotenvx_stub "$WORK_DIR/bin"

  export PATH="$WORK_DIR/bin:$PATH"
  export DOTENV_PRIVATE_KEY_REMOTE="test-key"
}

teardown_remote_env() {
  rm -rf "$WORK_DIR"
}

@test "setup-remote-env decrypts .env.remote into .env with only GH_TOKEN" {
  setup_remote_env
  touch "$WORK_DIR/repo/.env.remote"

  run bash "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"
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

  teardown_remote_env
}

@test "setup-remote-env skips decryption when .env.remote is missing" {
  setup_remote_env

  run bash "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *".env.remote not found"* ]]

  teardown_remote_env
}

@test "setup-remote-env skips decryption when DOTENV_PRIVATE_KEY_REMOTE is not set" {
  setup_remote_env
  touch "$WORK_DIR/repo/.env.remote"
  unset DOTENV_PRIVATE_KEY_REMOTE

  run bash "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"DOTENV_PRIVATE_KEY_REMOTE not set"* ]]

  teardown_remote_env
}

@test "setup-remote-env adds ~/.local/bin to PATH in ~/.bashrc" {
  setup_remote_env

  run bash "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"
  [ "$status" -eq 0 ]

  run grep -F 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"
  [ "$status" -eq 0 ]

  teardown_remote_env
}

@test "setup-remote-env adds .env source line to ~/.bashrc" {
  setup_remote_env
  touch "$WORK_DIR/repo/.env.remote"

  run bash "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"
  [ "$status" -eq 0 ]

  run grep -F "$WORK_DIR/repo/.env" "$HOME/.bashrc"
  [ "$status" -eq 0 ]

  teardown_remote_env
}

@test "setup-remote-env does not duplicate bashrc entries on re-run" {
  setup_remote_env
  touch "$WORK_DIR/repo/.env.remote"

  bash "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"
  bash "$WORK_DIR/repo/.codex/hooks/setup-remote-env.sh"

  count="$(grep -c 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" || true)"
  [ "$count" -eq 1 ]

  teardown_remote_env
}
