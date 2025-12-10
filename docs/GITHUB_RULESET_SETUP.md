# GitHub Ruleset とブランチ保護設定ガイド

このドキュメントでは、GitHub Ruleset とブランチ保護設定をテンプレート化して適用する方法を説明します。

## 概要

GitHub Ruleset を使用することで、以下の設定をコード化して管理できます：

- ブランチ保護ルール
- プルリクエストの必須レビュー
- ステータスチェックの必須化
- ブランチ削除の制限
- Bypass 設定（特定のユーザーやチームがルールを回避できる設定）
- ブランチマージ後の自動削除

## 前提条件

- GitHub CLI (gh) がインストールされていること
- リポジトリへの管理者権限があること

### GitHub CLI のインストール

```bash
# macOS
brew install gh

# Linux
# https://cli.github.com/manual/installation を参照

# Windows
# https://cli.github.com/manual/installation を参照
```

### GitHub CLI へのログイン

```bash
gh auth login
```

## セットアップ方法

### 方法1: 一括セットアップ（推奨）

すべての設定を一度に適用する場合：

```bash
chmod +x .github/scripts/setup-all.sh
./.github/scripts/setup-all.sh
```

### 方法2: 個別セットアップ

#### Ruleset の設定

```bash
chmod +x .github/scripts/setup-rulesets.sh
./.github/scripts/setup-rulesets.sh
```

このスクリプトは以下の Ruleset を適用します：

- **Branch Protection Ruleset**: `main`, `develop`, `release/*` ブランチ用
  - プルリクエスト必須
  - 1名以上の承認必須
  - CI ステータスチェック必須
  - ブランチ削除保護
  - 組織管理者は Bypass 可能

- **Feature Branch Ruleset**: `feature/*`, `feat/*` ブランチ用
  - プルリクエスト必須
  - 1名以上の承認必須
  - ステータスチェックは任意

#### ブランチ自動削除の設定

```bash
chmod +x .github/scripts/setup-branch-auto-delete.sh
./.github/scripts/setup-branch-auto-delete.sh
```

このスクリプトは、マージされたプルリクエストのブランチを自動的に削除する設定を有効にします。

## Ruleset テンプレートのカスタマイズ

### ブランチ保護 Ruleset のカスタマイズ

`.github/rulesets/branch-protection-ruleset.json` を編集して、以下の設定を変更できます：

#### 対象ブランチの変更

```json
{
  "conditions": {
    "ref_name": {
      "include": [
        "main",
        "develop",
        "release/*"
      ]
    }
  }
}
```

#### 必須レビュー数の変更

```json
{
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 2  // 2名以上の承認を必須にする
      }
    }
  ]
}
```

#### Bypass 設定の変更

```json
{
  "bypass_actors": [
    {
      "actor_id": 123456,  // チームIDまたはユーザーID
      "actor_type": "Team",  // Team, Integration, OrganizationAdmin
      "bypass_mode": "always"  // always, pull_request
    }
  ]
}
```

**Bypass Actor の ID を取得する方法：**

```bash
# チームIDを取得
gh api orgs/OWNER/teams --jq '.[] | select(.name == "TEAM_NAME") | {id: .id, name: .name}'

# ユーザーIDを取得
gh api users/USERNAME --jq '{id: .id, login: .login}'
```

### Feature Branch Ruleset のカスタマイズ

`.github/rulesets/feature-branch-ruleset.json` を編集して、フィーチャーブランチ用のルールをカスタマイズできます。

## 手動設定（UI を使用する場合）

スクリプトを使用しない場合は、GitHub の Web UI から手動で設定することもできます。

### Ruleset の手動設定

1. リポジトリの Settings > Rules > Rulesets に移動
2. "New ruleset" をクリック
3. "New branch ruleset" を選択
4. `.github/rulesets/` 内の JSON ファイルの内容を参考に設定

### ブランチ自動削除の手動設定

1. リポジトリの Settings > General > Pull Requests に移動
2. "Automatically delete head branches" を有効にする

## 既存の Ruleset の確認

```bash
# すべての Ruleset を一覧表示
gh api repos/OWNER/REPO/rulesets --jq '.[] | {id: .id, name: .name, enforcement: .enforcement}'

# 特定の Ruleset の詳細を表示
gh api repos/OWNER/REPO/rulesets/RULESET_ID
```

## トラブルシューティング

### 権限エラー

リポジトリへの管理者権限が必要です。権限を確認してください：

```bash
gh api repos/OWNER/REPO --jq '.permissions'
```

### Ruleset が適用されない

1. Ruleset の `enforcement` が `active` になっているか確認
2. ブランチ名が `conditions.ref_name.include` のパターンに一致しているか確認
3. Ruleset の順序を確認（複数の Ruleset がある場合、最初に一致したものが適用されます）

### Bypass が機能しない

1. `actor_id` が正しいか確認
2. `actor_type` が正しいか確認（Team, Integration, OrganizationAdmin）
3. `bypass_mode` が適切か確認（`always` または `pull_request`）

## 参考資料

- [GitHub Rulesets API ドキュメント](https://docs.github.com/en/rest/repos/rules)
- [Creating rulesets for a repository](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)
- [GitHub CLI ドキュメント](https://cli.github.com/manual/)
