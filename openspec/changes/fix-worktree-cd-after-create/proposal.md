# Fix: worktree 作成後に自動で cd する

## Why

`wt switch --create <branch-name>` で worktree を作成しても、シェルのカレントディレクトリが元のままになるため、Agent の表示では `main` ブランチのままとなり、実態（worktree 内の別ブランチ）と不一致になる。

## What

- worktree 作成後にカレントディレクトリを worktree 内に移動する手順を SKILL.md に追加
- `cd` パスは `git worktree list` または Worktrunk の出力から自動取得
