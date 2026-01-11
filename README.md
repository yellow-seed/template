# Template Repository

<!-- CI/CD & Code Quality -->
[![CI](https://github.com/yellow-seed/template/workflows/CI/badge.svg)](https://github.com/yellow-seed/template/actions/workflows/ci.yml)
[![Actionlint](https://github.com/yellow-seed/template/workflows/Actionlint/badge.svg)](https://github.com/yellow-seed/template/actions/workflows/actionlint.yml)
[![codecov](https://codecov.io/gh/yellow-seed/template/branch/main/graph/badge.svg)](https://codecov.io/gh/yellow-seed/template)

<!-- Project Info -->
[![License](https://img.shields.io/github/license/yellow-seed/template)](https://github.com/yellow-seed/template/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/yellow-seed/template)](https://github.com/yellow-seed/template/commits/main)

<!-- Repository Activity -->
[![GitHub stars](https://img.shields.io/github/stars/yellow-seed/template)](https://github.com/yellow-seed/template/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/yellow-seed/template)](https://github.com/yellow-seed/template/network/members)
[![GitHub issues](https://img.shields.io/github/issues/yellow-seed/template)](https://github.com/yellow-seed/template/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/yellow-seed/template)](https://github.com/yellow-seed/template/pulls)

<!-- Other Workflows -->
[![Claude Code](https://github.com/yellow-seed/template/workflows/Claude%20Code/badge.svg)](https://github.com/yellow-seed/template/actions/workflows/claude.yml)
[![Copilot Setup Steps](https://github.com/yellow-seed/template/workflows/Copilot%20Setup%20Steps/badge.svg)](https://github.com/yellow-seed/template/actions/workflows/copilot-setup-steps.yml)

汎用的な開発プロジェクト用のテンプレートリポジトリです。

## 概要

このリポジトリは、新しいプロジェクトを開始する際に必要な基本的な設定ファイルとテンプレートを含んでいます。

## 含まれる内容

### GitHub Actions ワークフロー

- `ci.yml` - 複数言語対応のCIワークフロー
- `actionlint.yml` - GitHub Actions YAMLの構文チェックワークフロー
- `claude.yml` - Claude AIによるコードレビューワークフロー
- `copilot-setup-steps.yml` - GitHub Copilotセットアップワークフロー
- `validate-scripts.yml` - スクリプトの検証ワークフロー

### Dependabot設定

- `.github/dependabot.yml` - 依存関係の自動更新設定

### Issue/PR テンプレート

- `bug_report.yml` - バグレポートテンプレート
- `feature_request.yml` - 機能リクエストテンプレート
- `todo.yml` - TODOタスクテンプレート
- `PULL_REQUEST_TEMPLATE.md` - プルリクエストテンプレート

### ドキュメント

- `AGENTS.md` - AIエージェント向けのドキュメント
- `CLAUDE.md` - Claude向けの設定/ドキュメント
- `docs/GITHUB_RULESET_SETUP.md` - GitHub Rulesetセットアップガイド

### 設定ファイル

- `.gitignore` - 複数言語対応の.gitignore（Ruby, Python, JavaScript/TypeScript, Go）
- `.gitattributes` - Git属性設定
- `codecov.yml` - Codecovの設定

### Claude Code スキル

- `.claude/skills/test-driven-development/` - TDD開発支援スキル
- `.claude/skills/github-issue/` - GitHub Issue作成スキル
- `.claude/skills/code-review/` - コードレビュースキル
- `.claude/skills/reviewing-security/` - セキュリティレビュースキル
- `.claude/skills/sample-explaining-code/` - コード説明スキル

### GitHub Ruleset とブランチ保護設定

- `.github/rulesets/` - Ruleset の JSON テンプレート
  - `branch-protection-ruleset.json` - メインブランチ用の保護ルール
  - `feature-branch-ruleset.json` - フィーチャーブランチ用のルール
- `.github/scripts/` - セットアップスクリプト
  - `setup-rulesets.sh` - Ruleset を適用するスクリプト
  - `setup-branch-auto-delete.sh` - ブランチ自動削除を有効にするスクリプト
  - `setup-github-project.sh` - GitHub Project を作成するスクリプト
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

chmod +x .github/scripts/setup-github-project.sh
./.github/scripts/setup-github-project.sh
```

詳細は [GITHUB_RULESET_SETUP.md](docs/GITHUB_RULESET_SETUP.md) を参照してください。
