# Template Repository

汎用的な開発プロジェクト用のテンプレートリポジトリです。

## 概要

このリポジトリは、新しいプロジェクトを開始する際に必要な基本的な設定ファイルとテンプレートを含んでいます。

## 含まれる内容

### GitHub Actions ワークフロー

- `dependabot.yml` - Dependabotの自動マージ設定
- `custom_setup.yml` - カスタムセットアップワークフロー
- `ci.yml` - 複数言語対応のCIワークフロー

### Issue/PR テンプレート

- `bug_report.yml` - バグレポートテンプレート
- `feature_request.yml` - 機能リクエストテンプレート
- `PULL_REQUEST_TEMPLATE.md` - プルリクエストテンプレート

### ドキュメント

- `AGENTS.md` - AIエージェント向けのドキュメント
- `CLAUDE.md` - Claude向けの設定/ドキュメント
- `CONTRIBUTING.md` - コントリビューションガイドライン
- `LICENSE` - ライセンスファイル（MIT）
- `.github/SECURITY.md` - セキュリティポリシー
- `LANGUAGE_SETUP.md` - 各言語の基本構成ガイド

### 設定ファイル

- `.gitignore` - 複数言語対応の.gitignore（Ruby, Python, JavaScript/TypeScript, Go）
- `.editorconfig` - エディタ設定の統一
- `.github/CODEOWNERS` - コードオーナー設定

### GitHub Ruleset とブランチ保護設定

- `.github/rulesets/` - Ruleset の JSON テンプレート
  - `branch-protection-ruleset.json` - メインブランチ用の保護ルール
  - `feature-branch-ruleset.json` - フィーチャーブランチ用のルール
- `.github/scripts/` - セットアップスクリプト
  - `setup-rulesets.sh` - Ruleset を適用するスクリプト
  - `setup-branch-auto-delete.sh` - ブランチ自動削除を有効にするスクリプト
  - `setup-all.sh` - すべての設定を一括で適用するスクリプト

詳細は [GITHUB_RULESET_SETUP.md](docs/GITHUB_RULESET_SETUP.md) を参照してください。

## 使用方法

1. このリポジトリをテンプレートとして使用するか、クローンしてください
2. プロジェクトに合わせて各ファイルをカスタマイズしてください
3. 必要に応じて言語別の設定ファイルを追加してください
4. GitHub Ruleset とブランチ保護設定を適用してください（オプション）

### GitHub Ruleset のセットアップ（オプション）

ブランチ保護や自動削除設定を適用する場合：

```bash
# すべての設定を一括で適用
chmod +x .github/scripts/setup-all.sh
./.github/scripts/setup-all.sh

# または個別に適用
chmod +x .github/scripts/setup-rulesets.sh
./.github/scripts/setup-rulesets.sh

chmod +x .github/scripts/setup-branch-auto-delete.sh
./.github/scripts/setup-branch-auto-delete.sh
```

詳細は [GITHUB_RULESET_SETUP.md](docs/GITHUB_RULESET_SETUP.md) を参照してください。
