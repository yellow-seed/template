---
name: git-branch-worktree
description: "ブランチ作成・切り替え・削除のスキル。_REMOTE 環境変数に応じて worktree（ローカル）または通常ブランチ（Web）を自動選択。Use when: 新ブランチの作成、ブランチ切り替え、並列開発環境のセットアップを依頼された時。"
---

# Git Branch & Worktree 管理

ブランチの作成・切り替え・削除を一元管理するスキル。
`*_REMOTE` 環境変数の有無に応じて、worktree（ローカルPC）または通常ブランチ（Web環境）を自動選択する。

## 環境判定

```bash
# *_REMOTE が設定されていれば Web 環境（通常ブランチ）
# 設定されていなければ ローカル環境（worktree）
is_remote_env() {
  env | grep -qE '^[A-Z_]+_REMOTE='
}
```

| 環境 | 判定 | ブランチ方式 |
|------|------|-------------|
| ローカルPC | `*_REMOTE` なし | git worktree + Worktrunk |
| Claude Code Web / Codex Web | `*_REMOTE=true` | 通常 git branch |

## ワークフロー

### ブランチ命名規約

ブランチ名は `{type}/{description}` 形式とする。

| 要素 | ルール | 例 |
|------|--------|-----|
| `type` | Conventional Commits と同一の type | `feat`, `fix`, `docs`, `refactor`, `test`, `chore` |
| `description` | kebab-case、簡潔に | `add-login`, `fix-memory-leak` |

**例:**
- `feat/add-user-auth`
- `fix/api-timeout`
- `docs/update-readme`
- `refactor/extract-validator`

Issue 番号を付ける場合は `{type}/{issue}-{description}` も許容する。
- `feat/123-add-user-auth`

### 1. ブランチ作成

**ローカル環境（worktree）**

```bash
wt switch --create <branch-name>
```

worktree は Worktrunk の user config にある `worktree-path` に従って作成される。
このテンプレートの標準配置は `~/worktrees/{{ repo }}/{{ branch | sanitize }}`。
`scripts/install-tools.sh` は user config が未設定の場合に次を追加する。

```toml
worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}"
```

作成後は worktree 側で `bash scripts/env-setup.sh` を実行し、依存インストールと環境セットアップを行う。

一時的に別の配置先を指定したい場合は、`WORKTRUNK_WORKTREE_PATH` を使う。

```bash
WORKTRUNK_WORKTREE_PATH="/path/to/worktrees/{{ repo }}/{{ branch | sanitize }}" wt switch --create <branch-name>
```

**Web環境（通常ブランチ）**

```bash
git checkout -b <branch-name>
git push -u origin <branch-name>
```

### 2. ブランチ切り替え

**ローカル環境（worktree）**

```bash
wt switch <branch-name>
```

**Web環境（通常ブランチ）**

```bash
git checkout <branch-name>
```

### 3. ブランチ削除

**ローカル環境（worktree）**

```bash
wt remove <branch-name>
```

**Web環境（通常ブランチ）**

```bash
git branch -d <branch-name>
git push origin --delete <branch-name>
```

### 4. 一覧表示

**ローカル環境（worktree）**

```bash
wt list
```

**Web環境（通常ブランチ）**

```bash
git branch -a
```

## 実装タスクでの使用

`/opsx:apply` で実装を行う際、このスキルを参照して適切なブランチ方式を選択する。

- Web環境では worktree は使用できないため、通常ブランチで作業
- ローカル環境では worktree を使用して並列開発を可能に

## Worktrunk 設定

worktree の配置先は Worktrunk の user config で定義する。
`.config/wt.toml` は project config であり、hooks や list 表示などチーム共有の設定に使う。
`worktree-path` は `.config/wt.toml` に書かず、user config（デフォルト: `~/.config/worktrunk/config.toml`）に書く。

```toml
worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}"
```

## 注意事項

- worktree 削除時には、そのブランチの変更は失われるため、事前にコミットまたはプッシュ
- Web環境では `wt` コマンドは使用しない
- Worktrunk の作成コマンドは `wt switch --create`。`wt create` は使用しない
- Worktrunk の削除コマンドは `wt remove`。`wt delete` は使用しない
