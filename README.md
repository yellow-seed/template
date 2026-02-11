# Template Repository

<!-- CI/CD & Code Quality -->

[![CI](https://github.com/yellow-seed/template/workflows/CI/badge.svg)](https://github.com/yellow-seed/template/actions/workflows/ci.yml)
[![Actionlint](https://github.com/yellow-seed/template/workflows/Actionlint/badge.svg)](https://github.com/yellow-seed/template/actions/workflows/actionlint.yml)
[![codecov](https://codecov.io/gh/yellow-seed/template/branch/main/graph/badge.svg)](https://codecov.io/gh/yellow-seed/template)

<!-- Project Info -->

[![License](https://img.shields.io/github/license/yellow-seed/template)](https://github.com/yellow-seed/template/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/yellow-seed/template)](https://github.com/yellow-seed/template/commits/main)

<!-- Repository Activity -->

[![GitHub issues](https://img.shields.io/github/issues/yellow-seed/template)](https://github.com/yellow-seed/template/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/yellow-seed/template)](https://github.com/yellow-seed/template/pulls)

汎用的な開発プロジェクト用のテンプレートリポジトリです。

## 概要

このリポジトリは、新しいプロジェクトを開始する際に必要な基本的な設定ファイルとテンプレートを含んでいます。

## 含まれる内容

### `.github/workflows/`

CI/CD、コードレビュー、コード品質チェックなどの自動化ワークフローを格納しています。

### `.github/ISSUE_TEMPLATE/`

バグレポート、機能リクエスト、タスク管理など、様々な用途のIssueテンプレートを格納しています。

### `.github/PULL_REQUEST_TEMPLATE.md`

統一されたPull Request形式を提供するテンプレートです。

### `.github/rulesets/`

ブランチ保護ルールやフィーチャーブランチルールなど、GitHub Ruleset用のJSONテンプレートを格納しています。

### `.github/scripts/`

Rulesetの適用、ブランチ自動削除、GitHub Project作成など、リポジトリセットアップを自動化するスクリプトを格納しています。詳細は [GITHUB_RULESET_SETUP.md](docs/GITHUB_RULESET_SETUP.md) を参照してください。

### `.github/dependabot.yml`

依存関係の自動更新設定です。

### `.github/skills/`

TDD開発、Issue作成、コードレビュー、セキュリティレビューなど、Claude Code用の開発支援スキルを格納しています。

**注意**: `.claude/skills/`は`.github/skills/`へのシンボリックリンクです。シンボリックリンクが機能しない環境（Windows管理者権限なしなど）では、`.claude/hooks/skills-setup.sh`を実行してください。

### `.claude/hooks/`

Claude Code on the Webでのセットアップスクリプトやスキルディレクトリのセットアップスクリプトを格納しています。

### `docs/`

プロジェクトのドキュメントを格納しています。

### ルートレベルの設定ファイル

- `AGENTS.md` - AIエージェント向けのプロジェクト情報
- `CLAUDE.md` - Claude向けの設定とドキュメント参照
- `.gitignore` - 複数言語対応（Ruby, Python, JavaScript/TypeScript, Go）
- `.gitattributes` - Git属性設定
- `codecov.yml` - コードカバレッジ設定
- `LICENSE` - MITライセンス

## 使用方法

1. このリポジトリをテンプレートとして使用するか、クローンしてください
2. プロジェクトに合わせて各ファイルをカスタマイズしてください
3. 必要に応じて言語別の設定ファイルを追加してください
4. GitHub Ruleset とブランチ保護設定を適用してください（オプション）

### GitHub Ruleset のセットアップ（オプション）

ブランチ保護や自動削除設定を適用する場合、以下のいずれかの方法で実行できます：

#### 方法1: GitHub Actions で実行（推奨）

リポジトリのオーナーまたは管理者権限を持つユーザーは、GitHub Actions から簡単にセットアップできます：

1. リポジトリの **Actions** タブを開く
2. **Setup Repository** ワークフローを選択
3. **Run workflow** ボタンをクリック
4. Dry-run モードを選択（初回はチェックを入れて動作確認することを推奨）
5. **Run workflow** で実行

**特徴:**

- リポジトリオーナー/管理者のみ実行可能（セキュリティ保護）
- Dry-run モードで事前確認可能
- ローカル環境不要

#### 方法2: ローカルでスクリプトを実行

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
