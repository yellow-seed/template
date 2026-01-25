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

## リモート環境（Codex）について

### 環境変数

- `CODEX_REMOTE`: リモート環境（Codex）の場合に`true`がセットされる

### リモート環境の特徴

`CODEX_REMOTE=true`の場合:

- DockerおよびDocker Composeは使用不可
- 代わりにPodmanが利用可能
- ネットワークはプロキシ経由（証明書の設定が必要な場合あり）

### Podman環境のセットアップ

リモート環境でコンテナビルドを行う場合は、以下のhookスクリプトを実行してください：

```bash
bash .codex/hooks/podman-setup.sh
```

このスクリプトは以下を行います：

1. Podmanのインストール（未インストールの場合）
2. プロキシ証明書のコピー
3. 統合Dockerfileを使用したコンテナビルド（`REMOTE_ENV=true`引数付き）

### コンテナビルドコマンド

```bash
# ローカル環境（Docker使用）
docker build -t dev-env .

# リモート環境（Podman使用、CODEX_REMOTE=trueの場合）
podman build --build-arg REMOTE_ENV=true --isolation=chroot -t dev-env .
```

## 開発環境のセットアップ

### Claude Code での GitHub CLI (gh) のセットアップ

Claude Code on the Web などのリモート環境で GitHub CLI (`gh`) コマンドを使用する場合は、以下のhookスクリプトを実行してください：

```bash
bash .claude/hooks/gh-setup.sh
```

### リモート環境での gh コマンド使用方法

gitのremoteがローカルプロキシを経由している環境では、`gh` コマンドがリポジトリを自動認識できない場合があります。その場合は以下の方法を使用してください：

方法: `-R` フラグでリポジトリを明示的に指定

sample

```bash
gh issue list -R yellow-seed/template
gh pr view 123 -R yellow-seed/template
```

### スキルディレクトリのセットアップ（Windows環境など）

このリポジトリでは、`.claude/skills` と `.codex/skills` は `.github/skills` へのシンボリックリンクとして構成されています。

**シンボリックリンクが機能しない環境**（Windows管理者権限なし、`core.symlinks=false`など）では、以下のスクリプトを実行してください：

```bash
bash .claude/hooks/skills-setup.sh
```

このスクリプトは`.github/skills`を`.claude/skills`と`.codex/skills`にコピーします。

**注意事項**:

- シンボリックリンク環境では、すべてのディレクトリは自動的に同期されます
- コピー環境では、`.github/skills`を変更した場合、再度`skills-setup.sh`を実行して同期する必要があります
- 新しいスキルを追加する際は、必ず`.github/skills/`に配置してください

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

### ドキュメント/設定ファイルのフォーマット

- PrettierでMarkdown/YAML/JSONをフォーマットします
- ローカル実行:
  - `npm install`
  - `npm run format:check` (チェック)
  - `npm run format` (自動フォーマット)
- Docker実行:
  - `docker build -t dev-env .`
  - `docker run --rm -v $(pwd):/workspace dev-env lint-docs`

## Pull Request 作成

このプロジェクトでは、`.github/PULL_REQUEST_TEMPLATE.md`のテンプレート形式に準拠した高品質なPull Requestを作成します。

詳細なガイドラインは [.claude/skills/pull-request/SKILL.md](.claude/skills/pull-request/SKILL.md) を参照してください。

## デプロイメント

<!-- デプロイメントの手順を記述してください -->

## その他の重要な情報

<!-- AIエージェントが知っておくべきその他の情報を記述してください -->
