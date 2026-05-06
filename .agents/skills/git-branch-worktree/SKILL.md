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
wt create <branch-name>
```

worktree は `~/Documents/worktrees/{{ repo }}/{{ branch | sanitize }}` に作成される。作成後は `bash scripts/env-setup.sh` で依存インストールと環境セットアップを実行。

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
wt delete <branch-name>
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

worktree の設定は `.config/wt.toml` で定義されている。

```toml
[worktree]
path = "~/Documents/worktrees/{{ repo }}/{{ branch | sanitize }}"
```

## 注意事項

- worktree 削除時には、そのブランチの変更は失われるため、事前にコミットまたはプッシュ
- Web環境では `wt` コマンドは使用しない
