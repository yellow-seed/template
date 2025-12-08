#!/bin/bash

# すべての GitHub 設定を一括でセットアップするスクリプト

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "GitHub 設定の一括セットアップ"
echo "=============================="
echo ""

# Ruleset のセットアップ
echo "1. Ruleset のセットアップを実行します..."
bash "$SCRIPT_DIR/setup-rulesets.sh"
echo ""

# ブランチ自動削除の設定
echo "2. ブランチ自動削除の設定を実行します..."
bash "$SCRIPT_DIR/setup-branch-auto-delete.sh"
echo ""

echo "すべてのセットアップが完了しました！"
