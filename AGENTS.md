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

<!-- テストの実行方法や戦略を記述してください -->

## Pull Request 作成

このプロジェクトでは、`.github/PULL_REQUEST_TEMPLATE.md`のテンプレート形式に準拠した高品質なPull Requestを作成します。

詳細なガイドラインは [.claude/skills/pull-request/SKILL.md](.claude/skills/pull-request/SKILL.md) を参照してください。

## デプロイメント

<!-- デプロイメントの手順を記述してください -->

## その他の重要な情報

<!-- AIエージェントが知っておくべきその他の情報を記述してください -->
