#!/bin/bash

# GitHub Project セットアップスクリプト
# このスクリプトは、GitHub CLI (gh) を使用して GitHub Project を設定します

set -e

# Dry-run モード（環境変数 DRY_RUN=1 で有効化）
DRY_RUN=${DRY_RUN:-0}

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitHub Project セットアップスクリプト${NC}"
echo "=================================="

if [ "$DRY_RUN" = "1" ]; then
    echo -e "${YELLOW}[DRY-RUN モード] 実際の変更は行いません${NC}"
    echo ""
fi

# GitHub CLI がインストールされているか確認
if ! command -v gh &> /dev/null; then
    echo -e "${RED}エラー: GitHub CLI (gh) がインストールされていません${NC}"
    echo "インストール方法: https://cli.github.com/"
    exit 1
fi

# GitHub CLI にログインしているか確認
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI にログインしていません${NC}"
    echo "ログインを実行します..."
    gh auth login
fi

# リポジトリ情報を取得
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
    echo -e "${RED}エラー: リポジトリ情報を取得できませんでした${NC}"
    echo "リポジトリのディレクトリで実行してください"
    exit 1
fi

REPO_NAME=$(gh repo view --json name -q .name 2>/dev/null || echo "")
OWNER=$(gh repo view --json owner -q .owner.login 2>/dev/null || echo "")

echo -e "${GREEN}リポジトリ: $REPO${NC}"
echo ""

# Project名を設定
PROJECT_TITLE="${REPO_NAME} Issue Tracker"

# 既存のProjectをチェック
echo "既存のProjectを確認中..."
EXISTING_PROJECT=$(gh project list --owner "$OWNER" --format json 2>/dev/null | jq -r ".projects[] | select(.title == \"$PROJECT_TITLE\") | .number" || echo "")

if [ -n "$EXISTING_PROJECT" ]; then
    echo -e "${YELLOW}既存のProject「$PROJECT_TITLE」が見つかりました (番号: $EXISTING_PROJECT)${NC}"

    if [ "$DRY_RUN" = "1" ]; then
        echo -e "${YELLOW}[DRY-RUN] Projectは既に存在します（スキップ）${NC}"
        exit 0
    else
        read -p "既存のProjectを使用しますか? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            PROJECT_NUMBER="$EXISTING_PROJECT"
            echo -e "${GREEN}既存のProjectを使用します${NC}"
        else
            echo -e "${YELLOW}スクリプトを終了します${NC}"
            exit 0
        fi
    fi
else
    if [ "$DRY_RUN" = "1" ]; then
        echo -e "${YELLOW}[DRY-RUN] 新しいProject「$PROJECT_TITLE」を作成します（スキップ）${NC}"
        exit 0
    else
        # 新しいProjectを作成
        echo -e "${GREEN}新しいProject「$PROJECT_TITLE」を作成中...${NC}"
        PROJECT_NUMBER=$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json 2>/dev/null | jq -r '.number')

        if [ -z "$PROJECT_NUMBER" ]; then
            echo -e "${RED}エラー: Projectの作成に失敗しました${NC}"
            exit 1
        fi

        echo -e "${GREEN}Project #$PROJECT_NUMBER を作成しました${NC}"
    fi
fi

# Projectのフィールドを設定
echo ""
echo -e "${GREEN}Projectのフィールドを設定中...${NC}"

# Status フィールド（デフォルトで存在する可能性があるので確認）
echo "Status フィールドを確認中..."
STATUS_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json 2>/dev/null | jq -r '.fields[] | select(.name == "Status") | .id' || echo "")

if [ -z "$STATUS_FIELD" ]; then
    echo "Status フィールドを作成中..."
    gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" --data-type "SINGLE_SELECT" --name "Status" 2>/dev/null || true

    # フィールドIDを再取得
    STATUS_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json 2>/dev/null | jq -r '.fields[] | select(.name == "Status") | .id' || echo "")
fi

# Statusフィールドにオプションを追加
if [ -n "$STATUS_FIELD" ]; then
    echo "Status フィールドにオプションを追加中..."
    for option in "Todo" "In Progress" "Done"; do
        gh api graphql -f query='
          mutation($projectId: ID!, $fieldId: ID!, $name: String!) {
            addProjectV2SingleSelectFieldOption(input: {
              projectId: $projectId
              fieldId: $fieldId
              name: $name
            }) {
              projectV2SingleSelectFieldOption {
                id
                name
              }
            }
          }' -f projectId="$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json | jq -r '.id')" -f fieldId="$STATUS_FIELD" -f name="$option" 2>/dev/null || true
    done
    echo -e "${GREEN}Status フィールドを設定しました${NC}"
else
    echo -e "${YELLOW}Status フィールドの作成をスキップしました${NC}"
fi

# Priority フィールド
echo "Priority フィールドを確認中..."
PRIORITY_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json 2>/dev/null | jq -r '.fields[] | select(.name == "Priority") | .id' || echo "")

if [ -z "$PRIORITY_FIELD" ]; then
    echo "Priority フィールドを作成中..."
    gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" --data-type "SINGLE_SELECT" --name "Priority" 2>/dev/null || true

    # フィールドIDを再取得
    PRIORITY_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json 2>/dev/null | jq -r '.fields[] | select(.name == "Priority") | .id' || echo "")
fi

# Priorityフィールドにオプションを追加
if [ -n "$PRIORITY_FIELD" ]; then
    echo "Priority フィールドにオプションを追加中..."
    PROJECT_ID=$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json | jq -r '.id')
    for option in "Low" "Medium" "High" "Critical"; do
        gh api graphql -f query='
          mutation($projectId: ID!, $fieldId: ID!, $name: String!) {
            addProjectV2SingleSelectFieldOption(input: {
              projectId: $projectId
              fieldId: $fieldId
              name: $name
            }) {
              projectV2SingleSelectFieldOption {
                id
                name
              }
            }
          }' -f projectId="$PROJECT_ID" -f fieldId="$PRIORITY_FIELD" -f name="$option" 2>/dev/null || true
    done
    echo -e "${GREEN}Priority フィールドを設定しました${NC}"
else
    echo -e "${YELLOW}Priority フィールドの作成をスキップしました${NC}"
fi

# Category フィールド
echo "Category フィールドを確認中..."
CATEGORY_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json 2>/dev/null | jq -r '.fields[] | select(.name == "Category") | .id' || echo "")

if [ -z "$CATEGORY_FIELD" ]; then
    echo "Category フィールドを作成中..."
    gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" --data-type "SINGLE_SELECT" --name "Category" 2>/dev/null || true

    # フィールドIDを再取得
    CATEGORY_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json 2>/dev/null | jq -r '.fields[] | select(.name == "Category") | .id' || echo "")
fi

# Categoryフィールドにオプションを追加
if [ -n "$CATEGORY_FIELD" ]; then
    echo "Category フィールドにオプションを追加中..."
    PROJECT_ID=$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json | jq -r '.id')
    for option in "Feature" "Bug" "Enhancement" "Documentation" "Refactor"; do
        gh api graphql -f query='
          mutation($projectId: ID!, $fieldId: ID!, $name: String!) {
            addProjectV2SingleSelectFieldOption(input: {
              projectId: $projectId
              fieldId: $fieldId
              name: $name
            }) {
              projectV2SingleSelectFieldOption {
                id
                name
              }
            }
          }' -f projectId="$PROJECT_ID" -f fieldId="$CATEGORY_FIELD" -f name="$option" 2>/dev/null || true
    done
    echo -e "${GREEN}Category フィールドを設定しました${NC}"
else
    echo -e "${YELLOW}Category フィールドの作成をスキップしました${NC}"
fi

echo ""
echo -e "${GREEN}セットアップが完了しました！${NC}"
echo -e "Project URL: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER"
echo ""
echo "次のステップ:"
echo "1. Projectページでビュー（Board/Table）をカスタマイズできます"
echo "2. リポジトリの設定でIssueの自動追加を有効にできます"
echo "3. gh project item-add コマンドで既存のIssueを追加できます"
