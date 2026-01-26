---
name: sync-codex
description: "Codex環境セットアップスキル。Codex向けの開発環境構築とカスタマイズ。Use when: Codex環境のセットアップ、env-setup.shのカスタマイズ、Codex固有の問題解決を依頼された時。"
---

# Codex環境セットアップ

Codex環境向けに必要なセットアップとカスタマイズを整理し、テンプレートベースのリポジトリで共通の開発環境を整えるためのスキルです。

## 目的

- Codex環境の制約を踏まえたセットアップ手順を提供する
- `.codex/hooks/` による自動化フローを明確にする
- プロジェクト固有のカスタマイズポイントを整理する

## Codex環境の特徴と制約

- **コンテナ環境**で動作するため、Dockerコマンドは利用できない
- セットアップは**シェルスクリプトを直接実行**して行う
- 既存の `.claude/hooks/` と共通化できる手順は再利用する

## セットアップ手順

### 1. GitHub CLIセットアップ

`.codex/hooks/gh-setup.sh` を使ってGitHub CLIをセットアップします。

```bash
bash .codex/hooks/gh-setup.sh
```

### 2. 開発環境セットアップ

`.codex/hooks/env-setup.sh` を使って必要なツールや依存関係を用意します。

```bash
bash .codex/hooks/env-setup.sh
```

### 3. スキルディレクトリのセットアップ

`.claude/hooks/skills-setup.sh` を利用して、`.github/skills` の内容を Codex 側のスキルディレクトリに同期します。

```bash
bash .claude/hooks/skills-setup.sh
```

## プロジェクト固有のカスタマイズ

### env-setup.sh のカスタマイズ

- プロジェクトで必要なツールやCLIを追加する
- 依存関係のインストールコマンドを追加する
- 既存コマンドを上書きせず、**追記**で拡張する

### プロジェクト固有のツール追加

- 例: Node.jsのバージョン管理ツール、Python仮想環境ツールなど
- インストール後にバージョン確認コマンドを入れて可視化する

### 言語/フレームワーク固有の設定

- Node.js: `npm install` や `pnpm install`
- Python: `pip install -r requirements.txt`
- Go: `go mod download`

## トラブルシューティング

### GitHub CLIの認証が失敗する

- `gh auth status` で認証状態を確認する
- 環境変数が不足している場合は設定を追加する

### env-setup.sh が途中で停止する

- 失敗したコマンドを切り分けて再実行する
- ログ出力を増やして原因を追跡する

### パス設定の問題

- `echo $PATH` でPATHを確認し、必要ならスクリプト内で追記する

## ベストプラクティス

- **冪等性の維持**: 何度実行しても安全に完了するようにする
- **エラーハンドリング**: `set -euo pipefail` や終了コードの確認を入れる
- **ログ出力**: 実行内容が追跡できるようにログを残す

## 他のスキルとの連携

- `template-sync` スキルと併用し、テンプレート同期時にCodex環境設定を適切に反映する
