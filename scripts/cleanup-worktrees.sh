#!/usr/bin/env bash
#
# cleanup-worktrees.sh - 不要な worktree の削除
#
# Usage:
#   bash scripts/cleanup-worktrees.sh [OPTIONS]
#
# Options:
#   --dry-run  削除せずに一覧のみ表示
#   --force    確認なしに一括削除
#   --help     ヘルプ表示

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }

DRY_RUN=true

parse_options() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--force)
			DRY_RUN=false
			shift
			;;
		--help | -h)
			show_help
			exit 0
			;;
		*)
			warn "Unknown option: $1"
			show_help
			exit 1
			;;
		esac
	done
}

show_help() {
	echo "Usage: bash scripts/cleanup-worktrees.sh [OPTIONS]"
	echo ""
	echo "Options:"
	echo "  --dry-run  削除せずに一覧のみ表示（デフォルト）"
	echo "  --force    確認なしに一括削除"
	echo "  --help     ヘルプ表示"
}

is_remote_env() {
	env | grep -qE '^[A-Z_]+_REMOTE='
}

main() {
	parse_options "$@"

	if is_remote_env; then
		info "Web環境のためworktree操作はスキップします"
		return
	fi

	info "=== Worktree の棚卸し ==="

	local main_worktree
	main_worktree=$(git rev-parse --show-toplevel)

	local worktrees
	worktrees=$(git worktree list 2>/dev/null | grep -v "$main_worktree" || true)

	if [[ -z $worktrees ]]; then
		ok "メイン以外のworktreeはありません"
		return
	fi

	echo ""
	echo "$worktrees" | while read -r line; do echo "  $line"; done
	echo ""

	if [[ $DRY_RUN == true ]]; then
		info "ドライランモード: 削除は実行されません"
		return
	fi

	if git worktree prune 2>/dev/null; then
		ok "stale worktree をクリーンアップしました"
	fi

	echo "$worktrees" | while read -r line; do
		local path branch
		path=$(echo "$line" | awk '{print $1}')
		branch=$(echo "$line" | awk '{print $2}')
		if wt remove "$branch" 2>/dev/null || git worktree remove "$path" 2>/dev/null; then
			ok "削除: $branch"
		else
			warn "スキップ: $branch"
		fi
	done
}

main "$@"
