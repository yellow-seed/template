## 1. Worktrunk 設定の修正

- [x] 1.1 `.config/wt.toml` から無効な `[worktree] path` 設定を取り除く
- [x] 1.2 `scripts/install-tools.sh` で user config の `worktree-path` を設定する
- [x] 1.3 `.mise.toml` の Worktrunk 指定を mise が解決できる GitHub backend に修正する

## 2. スキル文書の修正

- [x] 2.1 `.agents/skills/git-branch-worktree/SKILL.md` を `wt switch --create` ベースの正しい操作に更新する
- [x] 2.2 worktree 配置先は user config の `worktree-path` で管理することを明記する

## 3. 検証

- [x] 3.1 `wt config show` で無効キー警告が解消することを確認する
- [x] 3.2 Markdown / Shell の基本チェックを実行する
