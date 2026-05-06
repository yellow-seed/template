## 1. Skill スケルトン作成

- [x] 1.1 `.agents/skills/git-cleanup-audit/SKILL.md` を作成する
- [x] 1.2 SKILL.md に環境判定（ローカルPC vs Web）のセクションを追加する

## 2. ローカルブランチ削除スクリプト

- [x] 2.1 `scripts/cleanup-local-branches.sh` を作成する
- [x] 2.2 マージ済みローカルブランチのリストアップ機能を実装する
- [x] 2.3 `--dry-run` / `--force` モードを実装する

## 3. Worktree 削除スクリプト

- [x] 3.1 `scripts/cleanup-worktrees.sh` を作成する
- [x] 3.2 不要な worktree のリストアップ機能を実装する
- [x] 3.3 stale worktree のクリーンアップ機能を実装する
- [x] 3.4 `--dry-run` / `--force` モードを実装する

## 4. リモートブランチ削除スクリプト

- [x] 4.1 `scripts/cleanup-remote-branches.sh` を作成する
- [x] 4.2 PR close済みのリモートブランチ特定機能を実装する
- [x] 4.3 対応PRのない放置ブランチの特定機能を実装する
- [x] 4.4 `--dry-run` / `--force` モードを実装する

## 5. Issue 棚卸しスクリプト

- [x] 5.1 `scripts/audit-issues.sh` を作成する
- [x] 5.2 解決済み open Issue の特定機能を実装する
- [x] 5.3 close 候補の一覧表示機能を実装する

## 6. テスト・ドキュメント

- [x] 6.1 各スクリプトの bats テストを作成する
- [x] 6.2 AGENTS.md に本 skill の存在と使い方を追記する
