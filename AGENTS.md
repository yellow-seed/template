# AI Agents Documentation

このドキュメントは、AIエージェントがこのプロジェクトを理解し、適切に支援するための情報を提供します。

## プロジェクト概要

<!-- プロジェクトの概要を記述してください -->

## 技術スタック

<!-- 使用している技術スタックを記述してください -->
<!-- 例: Ruby on Rails, Python, Node.js, Go など -->

## ディレクトリ構造

<!-- プロジェクトのディレクトリ構造を説明してください -->

```
project/
├── src/
├── tests/
├── docs/
└── ...
```

## 開発環境のセットアップ

### Claude Code での GitHub CLI (gh) のセットアップ

Claude Code on the Web などのリモート環境で GitHub CLI (`gh`) コマンドを使用する場合は、以下のhookスクリプトを実行してください：

```bash
bash .claude/hooks/gh-setup.sh
```

このスクリプトは：
- リモート環境でのみ動作します（`CLAUDE_CODE_REMOTE=true` の場合）
- GitHub CLI が既にインストールされている場合はスキップします
- インストールされていない場合、`~/.local/bin` に自動的にインストールします
- PATH を自動的に設定し、`CLAUDE_ENV_FILE` に永続化します

**使用方法：**

AIエージェントに「claude hooks すれば gh コマンドが使える」と伝えることで、必要に応じてこのセットアップを実行できます。

**注意事項：**
- このスクリプトはSessionStart hookとして設計されており、セッション開始時に自動実行されることを想定しています
- ローカル環境では自動的にスキップされます
- 失敗しても安全に終了します（fail-safe設計）

## コーディング規約

<!-- プロジェクトで使用しているコーディング規約を記述してください -->

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

<!-- テストの実行方法や戦略を記述してください -->

## デプロイメント

<!-- デプロイメントの手順を記述してください -->

## その他の重要な情報

<!-- AIエージェントが知っておくべきその他の情報を記述してください -->

