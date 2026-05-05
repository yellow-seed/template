# AI Agents Documentation

このドキュメントは、AIエージェントがこのプロジェクトを理解し、適切に支援するための情報を提供します。

## プロジェクト概要

<!-- プロジェクトの概要を記述してください -->

## 技術スタック

<!-- 使用している技術スタックを記述してください -->
<!-- 例: Ruby on Rails, Python, Node.js, Go など -->

## ディレクトリ構造

<!-- プロジェクトのディレクトリ構造を説明してください -->

```bash
project/
├── src/
├── tests/
├── docs/
└── ...
```

## 開発環境のセットアップ

### スキルディレクトリのセットアップ（Windows環境など）

このリポジトリでは、`.claude/skills` は `.agents/skills` へのシンボリックリンクとして構成されています。

**シンボリックリンクが機能しない環境**（Windows管理者権限なし、`core.symlinks=false`など）では、以下のスクリプトを実行してください：

```bash
bash .claude/hooks/skills-setup.sh
```

このスクリプトは`.agents/skills`を`.claude/skills`にコピーします。

**注意事項**:

- シンボリックリンク環境では、すべてのディレクトリは自動的に同期されます
- コピー環境では、`.agents/skills`を変更した場合、再度`skills-setup.sh`を実行して同期する必要があります
- 新しいスキルを追加する際は、必ず`.agents/skills/`に配置してください

### dotenvx による環境変数管理

dotenvx で secret を扱う場合は、local / remote / prd の環境を分けて管理します。

- `local`: 人間のPC上で使う環境変数。復号鍵はAIエージェントへ渡さない
- `remote`: Claude Code on the web / Codex on the web など、AIのWeb実行環境専用の環境変数。AIに使わせてよい最小限の値だけを置く
- `prd`: 本番環境の環境変数。復号鍵や値をAIエージェントへ渡さない

Remote 用 `.env.remote` は local / prd の代替ではなく、AI作業用に分離した専用ファイルです。
Web 側 secret / environment variable には、値の実体ではなく `.env.remote` 用の `DOTENV_PRIVATE_KEY*` だけを登録します。
Remote 環境変数の参照は常に `dotenvx` 経由で行い、復号結果を `.bashrc` や永続ファイルへ書き出さないでください。
`scripts/env-setup.sh` はローカル開発環境向けのセットアップスクリプトであり、`.env.remote` を復号して `.env` を生成します。このスクリプトは Remote AI 環境（Codex/Claude Web）では使用しません。
`setup-remote-env.sh` は `DOTENV_PRIVATE_KEY*` が未設定の場合、セットアップフローを妨げないようスキップして正常終了します（exit 0）。鍵が設定済みで復号に失敗した場合のみ異常終了します（exit 1）。
dotenvx の新規導入、環境変数の追加、値の変更、ローテーションを行う場合は [.claude/skills/dotenvx-env/SKILL.md](.claude/skills/dotenvx-env/SKILL.md) を参照してください。

### Codex Web セットアップ確認

Codex Cloud environment settings の setup script には、remote 環境に必要な処理だけを明示的に登録します。

```bash
bash .codex/hooks/bootstrap-dotenvx.sh
bash .codex/hooks/bootstrap-gh.sh
bash .codex/hooks/setup-remote-env.sh
bash .codex/hooks/gh-setup.sh
```

`gh-setup.sh` は、先に用意された `gh` と `GH_TOKEN` または認証済みの `gh` を前提に GitHub CLI extensions などを設定します。

## 変更管理ワークフロー（OpenSpec）

このプロジェクトでは、AIエージェントへの**すべての実装依頼に OpenSpec ワークフローを使用します**。実装を始める前に必ず change を作成し、proposal.md と tasks.md を用意してください。

### 基本フロー

1. **提案** (`/opsx:propose`): `proposal.md`（なぜやるか＋Ref）と `tasks.md`（実装TODO）を生成
2. **実装** (`/opsx:apply`): `tasks.md` のタスクを順に実装・チェックオフ
3. **アーカイブ** (`/opsx:archive`): 完了した変更をアーカイブ（月次 GitHub Actions でも自動実行）

### スキーマの使い分け

| スキーマ | 用途 | コマンド |
| --- | --- | --- |
| `rapid`（デフォルト） | 小〜中規模の変更 | `openspec new change "<name>"` |
| `spec-driven` | 仕様書・設計書が必要な大規模変更 | `openspec new change --schema spec-driven "<name>"` |

詳細は [docs/OPENSPEC.md](docs/OPENSPEC.md) を参照してください。

## コーディング規約

<!-- プロジェクトで使用しているコーディング規約を記述してください -->

## コミットメッセージ規約

このプロジェクトでは、[Conventional Commits](https://www.conventionalcommits.org/)形式を使用しています。

### 形式

```yml
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

```git
feat: add user authentication

Implement JWT-based authentication system with login and logout endpoints.

Closes #123
```

```git
fix: resolve memory leak in data processing

The issue was caused by not properly releasing resources after processing.
This fix ensures all resources are cleaned up correctly.
```

## コミット粒度

適切なコミット粒度を保つことで、レビューが容易になり、問題発生時の原因特定や安全なrevertが可能になります。

### 基本原則

- **機能の意味のある単位でコミット**: 実装とそれが通るテストコードなど、機能的に独立した単位でコミットする
- **Pull Requestのすべての変更を一つのコミットにまとめない**: 複数の異なる目的の変更は別々のコミットに分割する

### 詳細なガイドライン

コミット分割の判断基準や実践例については、[.claude/skills/git-commit/SKILL.md](.claude/skills/git-commit/SKILL.md) を参照してください。

## テスト戦略

### CI 必要検証

CI で必要なツールは `shell-dev` コンテナに揃えています。
ローカル環境に `bats` / `qlty` などが無い場合でも、「確認できない」とせず、原則として次の Docker Compose 経由で検証します。

```bash
docker compose run --rm shell-dev scripts/run-checks.sh
docker compose run --rm shell-dev bats tests/*.bats
```

### ドキュメント/設定ファイルのフォーマット

- qltyでMarkdown/YAML/JSONをフォーマットします
- ローカル実行:
  - `npm install`
  - `qlty check --all` (チェック)
  - `qlty fmt --all` (自動フォーマット)
- Docker実行:
  - `docker compose run --rm shell-dev qlty check --all`

## Pull Request 作成

このプロジェクトでは、`.github/PULL_REQUEST_TEMPLATE.md`のテンプレート形式に準拠した高品質なPull Requestを作成します。

詳細なガイドラインは [.claude/skills/pull-request/SKILL.md](.claude/skills/pull-request/SKILL.md) を参照してください。

## デプロイメント

<!-- デプロイメントの手順を記述してください -->

## その他の重要な情報

<!-- AIエージェントが知っておくべきその他の情報を記述してください -->
