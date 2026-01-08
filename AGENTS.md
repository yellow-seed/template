# AI Agents Documentation

このドキュメントは、AIエージェントがこのプロジェクトを理解し、適切に支援するための情報を提供します。

## プロジェクト概要

汎用的な開発プロジェクト用のテンプレートリポジトリです。新しいプロジェクトを開始する際に必要な基本的な設定ファイル、GitHub Actions ワークフロー、Issue/PRテンプレート、Claude Code スキルなどを含んでいます。

## 技術スタック

- **GitHub Actions**: CI/CD ワークフロー
- **Bash/Shell Scripts**: セットアップスクリプト、自動化スクリプト
- **YAML**: 設定ファイル（GitHub Actions, Dependabot, Issue/PRテンプレート）
- **GitHub CLI (gh)**: GitHub操作の自動化
- **Bats**: シェルスクリプトのテストフレームワーク
- **Claude Code**: AIアシスタント統合（スキル、フック）

## ディレクトリ構造

```
template/
├── .github/
│   ├── ISSUE_TEMPLATE/       # Issue テンプレート（bug_report, feature_request, todo）
│   ├── workflows/            # GitHub Actions ワークフロー
│   ├── rulesets/             # GitHub Ruleset 設定（JSON）
│   └── scripts/              # セットアップスクリプト
│       └── tests/            # スクリプトのテストファイル（Bats）
├── .claude/
│   ├── hooks/                # Claude Code フック（gh-setup.sh）
│   └── skills/               # Claude Code スキル
│       ├── code-review/      # コードレビュースキル
│       ├── commit-message/   # コミットメッセージ作成スキル
│       ├── github-issue/     # GitHub Issue作成スキル
│       ├── reviewing-security/ # セキュリティレビュースキル
│       └── test-driven-development/ # TDD開発支援スキル
├── docs/                     # ドキュメント
│   └── GITHUB_RULESET_SETUP.md
├── AGENTS.md                 # AIエージェント向けドキュメント
├── CLAUDE.md                 # Claude向け設定
├── README.md                 # プロジェクトREADME
└── その他の設定ファイル（.gitignore, .gitattributes, codecov.yml等）
```

## 開発環境のセットアップ

### Claude Code での GitHub CLI (gh) のセットアップ

Claude Code on the Web などのリモート環境で GitHub CLI (`gh`) コマンドを使用する場合は、以下のhookスクリプトを実行してください：

```bash
bash .claude/hooks/gh-setup.sh
```

## コーディング規約

### シェルスクリプト

- **Shebang**: `#!/usr/bin/env bash` を使用
- **エラーハンドリング**: `set -euo pipefail` を設定（fail-safe設計）
- **関数**: 再利用可能な処理は関数化
- **ログ出力**: 処理の進行状況を明確に出力

### YAML

- **インデント**: 2スペース
- **GitHub Actions**: 適切なワークフロー名とジョブ名を設定
- **コメント**: 複雑な処理には説明コメントを追加

## コミットメッセージ規約

このプロジェクトでは、[Conventional Commits](https://www.conventionalcommits.org/)形式を使用しています。

### 形式

```
<type>: <subject>

<body>

<footer>
```

### Type（必須）

- `feat`: 新機能の追加
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの動作に影響しない変更（フォーマット、セミコロンなど）
- `refactor`: バグ修正や機能追加ではないコード変更
- `perf`: パフォーマンス改善
- `test`: テストの追加や修正
- `chore`: ビルドプロセスやツールの変更

### Subject（必須）

- 50文字以内
- 命令形で記述（例: "Add" ではなく "Adds" でもなく "Add"）
- 最初の文字は大文字にしない
- 末尾にピリオドを付けない

### Body（オプション）

- 変更の理由や方法を説明
- 72文字で折り返す
- 命令形で記述

### Footer（オプション）

- 破壊的変更がある場合は `BREAKING CHANGE:` を記載
- Issue番号を参照する場合は `Closes #123` など

### 例

```
feat: add user authentication

Implement JWT-based authentication system with login and logout endpoints.

Closes #123
```

```
fix: resolve memory leak in data processing

The issue was caused by not properly releasing resources after processing.
This fix ensures all resources are cleaned up correctly.
```

## テスト戦略

### シェルスクリプトのテスト

- **フレームワーク**: Bats (Bash Automated Testing System)
- **テストファイル**: `.github/scripts/tests/` ディレクトリ内
- **実行方法**: GitHub Actions の `validate-scripts.yml` ワークフローで自動実行
- **カバレッジ**: セットアップスクリプトの主要な機能をテスト

### GitHub Actions

- **Linting**: `actionlint.yml` ワークフローでYAML構文チェック
- **CI**: 複数言語に対応したCIワークフロー（`ci.yml`）

## デプロイメント

このテンプレートリポジトリ自体はデプロイ対象ではありません。

### テンプレートの使用方法

1. このリポジトリをテンプレートとして新しいリポジトリを作成
2. プロジェクトに合わせて各ファイルをカスタマイズ
3. 必要に応じて言語別の設定ファイルを追加
4. GitHub Ruleset とブランチ保護設定を適用（オプション）

詳細は [README.md](README.md) および [GITHUB_RULESET_SETUP.md](docs/GITHUB_RULESET_SETUP.md) を参照してください。

## その他の重要な情報

### Claude Code スキル

このリポジトリには、AIエージェントの作業を支援する複数のスキルが含まれています：

- **code-review**: ブランチとリモートオリジンの差分を分析するコードレビュースキル
- **commit-message**: Conventional Commits形式の日本語コミットメッセージを作成
- **github-issue**: `.github/ISSUE_TEMPLATE/` のテンプレート形式に準拠したIssueを作成
- **reviewing-security**: OWASP API Security Top 10に基づくセキュリティレビュー
- **test-driven-development**: TDD（テスト駆動開発）のRed-Green-Refactorサイクルをサポート

### GitHub CLI (gh) の自動セットアップ

リモート環境（Claude Code on the Web等）で使用する場合、SessionStart hookとして `.claude/hooks/gh-setup.sh` が実行され、GitHub CLIが自動的にセットアップされます。

#### リモート環境での gh コマンド使用方法

gitのremoteがローカルプロキシを経由している環境では、`gh` コマンドがリポジトリを自動認識できない場合があります。その場合は以下の方法を使用してください：

**方法1: `-R` フラグでリポジトリを明示的に指定**
```bash
gh issue list -R yellow-seed/template
gh pr view 123 -R yellow-seed/template
```

**方法2: 環境変数 `GITHUB_REPOSITORY` を設定**
```bash
export GITHUB_REPOSITORY=yellow-seed/template
gh issue list
```

セットアップスクリプトは自動的に `GITHUB_REPOSITORY` 環境変数をサポートしています。

### GitHub Ruleset

`.github/rulesets/` および `.github/scripts/` にブランチ保護やプロジェクト管理の自動化スクリプトが含まれています。詳細は [GITHUB_RULESET_SETUP.md](docs/GITHUB_RULESET_SETUP.md) を参照してください。

