## なぜやるか

ローカルPCでの開発において、git worktree + Worktrunk を導入することで、ブランチの切り替えに伴う依存インストールや環境セットアップの待ち時間を排除し、複数のタスクを並列で進められるようにする。特に AI コーディングエージェント（Claude Code, Codex）を複数ブランチで同時に走らせるワークフローにおいて、開発スピードの大幅な向上が見込める。

## 検討事項

### worktree の配置先

デフォルト設定（`{{ repo_path }}/../{{ repo }}.{{ branch | sanitize }}`）のままにすると、`~/Documents/GitHub/` 直下に `template.feature-xxx` のようなディレクトリが大量に生成され、散らかる。

**案A: 専用ディレクトリに集約（Recommended）**

```
worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}"
```

- メリット: リポジトリディレクトリが完全に分離され、`~/Documents/GitHub/` が散らからない
- メリット: Finder や `ls` で見えない場所に置ける
- デメリット: パスがリポジトリと別の場所になるため、慣れるまで少し意識が必要

**案B: リポジトリ内に隠す**

```
worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"
```

- メリット: リポジトリ配下にすべて収まる。パスが近い
- デメリット: `.worktrees/` が `git status` 等で表示されないよう `.gitignore` 追加が必要
- デメリット: リポジトリディレクトリ内に大量のサブディレクトリが物理的に存在する

このリポジトリでは **案A** を推奨する。理由：
1. `~/Documents/GitHub/` は開発者が頻繁にアクセスする場所であり、散らからない方がよい
2. Worktrunk の `wt list` / `wt switch` で管理するため、パスを手で意識する機会は少ない
3. 複数リポジトリを横断して worktree を管理する場合も一箇所に集約される

## Ref

- [git worktree を Worktrunk で管理したら手放せなくなった](https://zenn.dev/edash_tech_blog/articles/69d01f875dcccd)
- [Worktrunk 公式ドキュメント](https://worktrunk.dev/)
- [Worktrunk GitHub リポジトリ](https://github.com/max-sixty/worktrunk)
