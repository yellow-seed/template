# takt 導入計画

## 概要

takt（Task Agent Koordination Tool）は、複数のAIエージェントが協調して動作するワークフローを YAML で定義・実行するための npm パッケージ。
主に「相互レビュー」「自律的なコーディング〜PR作成」などのマルチエージェントワークフローを実現する。

- GitHub: https://github.com/nrslib/takt
- 作者: nrslib

---

## takt の主要概念

| 概念                  | 説明                                                                                             |
| --------------------- | ------------------------------------------------------------------------------------------------ |
| **Piece**             | ワークフロー定義（YAML ファイル）。処理全体の設計図                                              |
| **Movement**          | ワークフロー内の各ステップ。条件分岐・並列実行が可能                                             |
| **Persona**           | エージェントの役割定義（Markdown ファイル）。planner, coder, reviewer など                       |
| **Faceted Prompting** | Persona / Policy / Instruction / Knowledge / Output Contract の5要素でプロンプトを構造化する手法 |

### 組み込み Persona 例

- `planner` - タスク分解・計画立案
- `architect-planner` - アーキテクチャ設計
- `coder` - コーディング
- `ai-antipattern-reviewer` - AIアンチパターンレビュー
- `architecture-reviewer` - アーキテクチャレビュー
- `qa-reviewer` - QAレビュー
- `security-reviewer` - セキュリティレビュー
- `supervisor` - 全体監督・最終判断

---

## AI エージェント相互レビューの仕組み

```yaml
movements:
  - name: reviewers
    parallel:
      - name: arch-review
        persona: architecture-reviewer
      - name: qa-review
        persona: qa-reviewer
    rules:
      - condition: all("approved")
        next: supervise
      - condition: any("needs_fix")
        next: fix
```

並列 Movement で複数エージェントが同時にレビューし、全員 `approved` なら次へ進む。
一人でも `needs_fix` を返せば修正ステップに戻る。これが「相互レビュー」の実体。

---

## このリポジトリへの導入に必要な段取り

### Phase 1: 前提確認・準備

- [ ] **Anthropic API Key の確認**
  - `TAKT_ANTHROPIC_API_KEY` が必要（Claude を使う場合）
  - GitHub Secrets に登録するか、ローカル環境変数に設定
- [ ] **Node.js 環境の確認**
  - takt は npm パッケージなので Node.js が必要
  - 現在の `package.json` に追記 or グローバルインストールを選択
- [ ] **takt のインストール方式を決定**
  - グローバル: `npm install -g takt`
  - ローカル: `npm install --save-dev takt`（推奨 — バージョン固定可能）

### Phase 2: 基本設定ファイルの作成

```
.takt/
├── config.yaml          # デフォルト Piece・プロバイダ設定
├── pieces/              # ワークフロー定義 YAML
│   ├── code-review.yaml
│   ├── feature-dev.yaml
│   └── security-review.yaml
└── personas/            # カスタム Persona（Markdown）
    ├── coder.md
    └── reviewer.md
```

**`.takt/config.yaml` の基本形**:

```yaml
piece: default
provider: claude
```

**Piece YAML の基本形（例: code-review.yaml）**:

```yaml
name: code-review
description: アーキテクチャ・QA・セキュリティの3エージェント相互レビュー
max_iterations: 10
initial_movement: review

personas:
  arch-reviewer: ~/.takt/personas/architecture-reviewer.md
  qa-reviewer: ~/.takt/personas/qa-reviewer.md
  security-reviewer: ~/.takt/personas/security-reviewer.md
  supervisor: ~/.takt/personas/supervisor.md

movements:
  - name: review
    parallel:
      - name: arch-review
        persona: arch-reviewer
      - name: qa-review
        persona: qa-reviewer
      - name: security-review
        persona: security-reviewer
    rules:
      - condition: all("approved")
        next: supervise
      - condition: any("needs_fix")
        next: fix

  - name: fix
    persona: coder
    edit: true
    instruction_template: |
      レビュー指摘を修正してください。
      {previous_response}
    rules:
      - condition: done
        next: review

  - name: supervise
    persona: supervisor
    rules:
      - condition: approved
        next: COMPLETE
      - condition: needs_fix
        next: fix
```

### Phase 3: GitHub Actions 統合

`takt-action` を使うと、Issue に `@takt` とメンションするだけで takt が起動する。

```yaml
# .github/workflows/takt.yml
name: takt

on:
  issue_comment:
    types: [created]
  issues:
    types: [opened, labeled]

jobs:
  takt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: nrslib/takt-action@main
        with:
          anthropic_api_key: ${{ secrets.TAKT_ANTHROPIC_API_KEY }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

**必要な GitHub Secrets**:

| Secret 名                | 値                                  |
| ------------------------ | ----------------------------------- |
| `TAKT_ANTHROPIC_API_KEY` | Anthropic API Key                   |
| `GITHUB_TOKEN`           | 自動提供（actions権限の確認が必要） |

### Phase 4: 既存ワークフローとの統合

このリポジトリは OpenSpec ワークフロー・Claude Code スキルが整備されているため、以下の統合方針を推奨する。

| 既存の仕組み                   | takt との役割分担                              |
| ------------------------------ | ---------------------------------------------- |
| `openspec-propose` スキル      | 設計フェーズ（人間主導）                       |
| `openspec-apply-change` スキル | 実装フェーズ（Claude Code が担当）             |
| takt `code-review` Piece       | レビューフェーズ（マルチエージェント自律実行） |
| `react-to-review` スキル       | レビュー対応（Claude Code が担当）             |
| takt `feature-dev` Piece       | Issue → 実装 → PR まで完全自律実行             |

**完全自律ワークフローのイメージ**:

```
GitHub Issue 作成
    ↓
takt-action が検知
    ↓
planner Movement: タスク分解
    ↓
coder Movement: 実装（worktree 上）
    ↓
reviewers Movement（並列）:
  arch-reviewer / qa-reviewer / security-reviewer
    ↓ all("approved")
supervisor Movement: 最終承認
    ↓
PR 自動作成（--auto-pr）
```

### Phase 5: 環境設定ファイルへの追記

#### `scripts/install-tools.sh` への追加

```bash
# takt のインストール
npm install -g takt
```

#### `AGENTS.md` への追記

takt の使い方・Piece 定義の場所・カスタム Persona の置き場所をドキュメント化する。

#### `.qlty/qlty.toml` の更新

`.takt/pieces/**` を prettier の除外対象に追加することを検討。

---

## 導入ロードマップ

```
Week 1: Phase 1-2
  - API Key 準備
  - npm install takt
  - .takt/ ディレクトリ作成
  - code-review Piece の初期版作成

Week 2: Phase 3
  - .github/workflows/takt.yml 作成
  - GitHub Secrets 設定
  - Issue でのテスト実行

Week 3-4: Phase 4-5
  - OpenSpec との統合
  - feature-dev Piece の作成
  - ドキュメント整備
```

---

## 注意点・リスク

| 項目                      | 内容                                                                                                                        |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **API コスト**            | マルチエージェントは API 呼び出しが多い。Piece の `max_iterations` を適切に設定する                                         |
| **ループリスク**          | Movement 間でループしないよう条件分岐を慎重に設計する                                                                       |
| **worktree 衝突**         | 並列実行時の worktree ブランチ競合に注意                                                                                    |
| **GitHub Actions 権限**   | PR 作成・コメント投稿には適切な `GITHUB_TOKEN` 権限が必要                                                                   |
| **モデル選択**            | Opus は高性能だがコスト高。レビュー系は Sonnet で十分なケースが多い                                                         |
| **Codex/Cursor との混用** | takt は Claude Code・Codex・Cursor に対応しているが、このリポジトリは Claude Code 中心のため、`provider: claude` で統一推奨 |

---

## 参考リンク

- takt GitHub: https://github.com/nrslib/takt
- takt-action: https://github.com/nrslib/takt-action
- 参考記事1（coji）: https://zenn.dev/coji/articles/takt-multi-agent-coding-experience
- 参考記事2（nrs）: https://zenn.dev/nrs/articles/c6842288a526d7
