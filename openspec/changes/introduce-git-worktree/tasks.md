## 1. ツールの整備

- [ ] 1.1 `.mise.toml` に worktrunk を追加
- [ ] 1.2 `scripts/install-tools.sh` に worktrunk のシェル統合セットアップ処理を追加（`wt config shell install`）

## 2. プロジェクト設定

- [ ] 2.1 `.config/wt.toml` を作成（worktree パスは `~/worktrees/{{ repo }}/{{ branch | sanitize }}` を採用）
- [ ] 2.2 `.gitignore` を修正（`.config/wt.toml` をリポジトリ管理対象に含めるため `/ .config` パターンの調整）
- [ ] 2.3 `.worktreeinclude` を作成（`.env` ファイルのコピー用）

## 3. スクリプトの整備

- [ ] 3.1 worktree 作成時の依存インストール用 Hook スクリプトを作成
- [ ] 3.2 `scripts/env-setup.sh` を worktree 環境でも動作するように確認・修正

## 4. ドキュメント

- [ ] 4.1 `AGENTS.md` に Worktrunk の使い方とワークフローを追記
- [ ] 4.2 `docs/` に git worktree 開発ガイドドキュメントを作成
