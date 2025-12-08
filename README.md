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

## 使用方法

1. このリポジトリをテンプレートとして使用するか、クローンしてください
2. プロジェクトに合わせて各ファイルをカスタマイズしてください
3. 必要に応じて言語別の設定ファイルを追加してください

## 対応言語

このテンプレートは以下の言語に対応しています：

- Ruby
- Python
- JavaScript / TypeScript
- Go

各言語の基本構成については、[LANGUAGE_SETUP.md](LANGUAGE_SETUP.md)を参照してください。

## ライセンス

MIT License - 詳細は[LICENSE](LICENSE)を参照してください。

## コントリビューション

コントリビューションを歓迎します！詳細は[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。
