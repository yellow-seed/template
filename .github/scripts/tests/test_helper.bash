#!/usr/bin/env bash

# bats-support / bats-assert がある場合は利用する。
if [ -f "/usr/lib/bats-support/load.bash" ]; then
	load "/usr/lib/bats-support/load.bash"
	load "/usr/lib/bats-assert/load.bash"
elif [ -f "/usr/local/lib/bats/bats-support/load" ]; then
	load "/usr/local/lib/bats/bats-support/load"
	load "/usr/local/lib/bats/bats-assert/load"
elif [ -f "/opt/homebrew/lib/bats/bats-support/load" ]; then
	load "/opt/homebrew/lib/bats/bats-support/load"
	load "/opt/homebrew/lib/bats/bats-assert/load"
fi

# 依存ライブラリがない環境向けの最小アサーション実装。
if ! command -v assert >/dev/null 2>&1; then
	assert() {
		"$@"
	}
fi

if ! command -v assert_success >/dev/null 2>&1; then
	assert_success() {
		# shellcheck disable=SC2154
		[ "$status" -eq 0 ]
	}
fi

if ! command -v assert_failure >/dev/null 2>&1; then
	assert_failure() {
		# shellcheck disable=SC2154
		[ "$status" -ne 0 ]
	}
fi

if ! command -v assert_output >/dev/null 2>&1; then
	assert_output() {
		if [ "${1:-}" = "--partial" ]; then
			local expected=${2:-}
			# shellcheck disable=SC2154
			[[ "$output" == *"$expected"* ]]
			return
		fi

		local expected=${1:-}
		# shellcheck disable=SC2154
		[ "$output" = "$expected" ]
	}
fi
