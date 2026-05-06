## なぜやるか

Worktrunk の worktree 配置先設定が、実際には Worktrunk に無視される形式で `.config/wt.toml` に書かれているため、指定したパスに worktree が作成されない。スキルとセットアップ手順を Worktrunk の現在の設定仕様に合わせ、今後のブランチ作成時に期待した集中ディレクトリへ worktree が作られるようにする。

## Ref

- [Worktrunk configuration](https://worktrunk.dev)
- `wt config show`
