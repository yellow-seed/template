---
name: template-sync
description: "テンプレート同期スキル。yellow-seed/template と派生リポジトリ間の変更のやりとりを支援（Pull: テンプレート→子へ反映、Push: 子で得た改善をテンプレートへ還流）。Use when: テンプレート更新の反映、派生→template へのフィードバック、template 同期全般。"
---

# テンプレート同期

`yellow-seed/template` をベースにしたリポジトリとテンプレート本体のあいだで、**どちら向きに差分を運ぶか**に応じて手順を選ぶ。ファイルパスより**パターン（役割）**で考え、将来追加されるパスにも追従しやすくする。

## 同期の向き（Pull と Push）

| 向き | ソース（起点） | 宛先 | いつ使うか |
|------|----------------|------|------------|
| **Pull** | `yellow-seed/template`（既定: `main`） | このテンプレートから作った**派生リポジトリ** | テンプレ側の改善・CI・スキルを下流へ取り込む |
| **Push** | **派生リポジトリ**で検証済みの、テンプレートに**そのまま載せられる**変更 | `yellow-seed/template` | 現場で効いた修正・スキル・共通スクリプトを上流へ還す |

Push は「派生のすべてをマージする」のではなく、**一般化でき、秘密情報やプロジェクト固有情報が含まれない差分**だけを選ぶ。Pull と対になる概念として整理する。

## 共通原則

1. **非破壊**: 派生側の既存カスタムを前提にし、上書きで消さない
2. **選択的**: 取り込む変更は必要なものだけに絞る
3. **カスタム維持**: アプリ固有の設定・ワークフローは尊重する
4. **説明可能**: 何を・なぜ・どこから来たかをコミット／PR で残す
5. **事前確認**: 広い差分はブランチや PR でレビューしてから適用
6. **パターン志向**: 単一パス列挙に頼らず、ディレクトリの役割で判断する

## 対象パターンと同期のしかた

| 区分 | パス・例 | 同期のしかた |
|------|-----------|----------------|
| GitHub | `.github/**/*` | 新規は追加しやすい。既存ワークフローは**構造**（トリガー・ジョブ分割・依存）はテンプレに寄せ、**コマンド**はスタックに合わせて維持または個別調整 |
| AI エージェント設定 | `.agents/**`, `.Codex/**`, `.codex/**`, `.cursor/**`, `.aider/**`, `.codeium/**`, `.copilot/**` など、`skills/`・`hooks/` を含むドット配下 | `skills/` は追加・更新確認。`hooks/` は差分確認。シンボリックリンクできない環境は既存の `skills-setup` 系スクリプト方針に従う |
| ツール・CI 設定 | `.editorconfig`, `.prettierrc*`, `.eslintrc*`, `.codecov.yml`, `.renovate.json`, `.dependabot/**` など | 新規は追加。既存は差分を見てテンプレ基準値とのすり合わせやマージ |
| スクリプト | `scripts/**/*` | 新規追加、既存は差分レビュー。Dockerfile 等へのインライン手順は可能なら `scripts/` へ寄せる提案もあり |
| Git メタ | `.gitignore`, `.gitattributes`, `.gitmodules` | 行・ブロック単位でマージし、重複を避けて足す |
| フック | `.githooks/**/*` | テンプレと共通のフックを足す／更新。プロジェクト専用フックは残す |
| ドキュメント | `README.md`, `AGENTS.md`, `CONTRIBUTING.md` | **README**: 先頭付近のバッジ用コメントブロックなど、テンプレと決めた「同期区間」だけ置換・追従。**AGENTS.md**: 見出し構造をテンプレのお手本に寄せ、中身はプロジェクトに合わせて保持 |

**同期しない（原則）**: アプリのマニフェストやランタイム中心のファイル（例: `package.json` の依存解決そのもの、`Cargo.toml` のクレート選定など）はテンプレ同期の対象外。テンプレが用意する**周辺ツール・運用**に限定する。

## 同期タイプ早見

| タイプ | 例 | 動き |
|--------|-----|------|
| 完全同期 | 新規 `.github/workflows/*.yml`、新規 Issue テンプレ | テンプレからそのまま追加 |
| 構造同期 | 既存ワークフローの `on:` / ジョブ分割 | パターンはテンプレ、実行コマンドはプロジェクト次第 |
| マージ同期 | `.gitignore` | 既存を残しつつ不足分を追加 |
| 値同期 | `.codecov.yml`, `.renovate.json` | 組織基準に合わせて数値・ポリシーを揃える（例外は明示） |
| 選択的同期 | README のバッジコメントブロック | 区間だけ差し替え |
| 差分同期 | `scripts/`, `.githooks/` | 差分をレビューしてから適用 |

## Pull 型: テンプレート → 派生リポジトリ

派生リポのルートで、テンプレをリモートとして一時的に参照し差分を取る。

```bash
TEMPLATE_REPO="${TEMPLATE_REPO:-https://github.com/yellow-seed/template.git}"
git remote add template "$TEMPLATE_REPO" 2>/dev/null || true
git fetch template main

git diff HEAD template/main --name-only
git diff HEAD template/main -- .github/
git diff HEAD template/main -- .agents/ .claude/ .codex/ .cursor/ .Codex/ 2>/dev/null
git diff HEAD template/main -- scripts/ .githooks/
git diff HEAD template/main -- README.md AGENTS.md

# 単ファイル取得の例
git show template/main:.github/workflows/example.yml
```

**手順の流れ**

1. `TEMPLATE_REPO` の `main` を fetch（必要ならタグ／コミットを記録）
2. 言語・既存 CI・カスタムの有無を把握（盲目的な全適用はしない）
3. 名前のみ／ディレクトリ構造の差分と、中身の差分を分けて見る
4. 「追加してよい新規」「マージが必要な既存」「スタック依存でスキップ」を仕分け
5. `git show` / `git checkout template/main -- path` / 手動マージで適用
6. 動作確認・`chore:` 等でコミット（本文に `template@<短いSHA>` を含めるとよい）
7. 一時リモートを消すなら `git remote remove template`

**ワークフロー（GitHub Actions）**: テンプレは `paths-ignore`・`branches`・ジョブ分割など**運用パターン**のお手本にする。`npm test` / `pytest` など**実行コマンド**は派生のスタックに合わせ、テンプレに合わせて壊さない。

**README バッジ**: テンプレ側でコメント（例: `<!-- CI/CD ... -->`）で囲んだ区間を決め、そこだけを同期し、リポジトリ名は派生のオーナー／名前に置換する。

## Push 型: 派生リポジトリ → テンプレート

派生で効いた変更を `yellow-seed/template` に取り込み、ほかの派生が Pull で恩恵を受けられるようにする。

**還流してよい候補の条件**

- **汎用化できる**（プロジェクト名・秘密・内部 URL が残らない）
- **ライセンス・社内規程**で外部公開テンプレに載せて問題ない
- 可能なら**小さなコミット単位**で説明しやすい

**手順の流れ**

1. 派生側で、還流対象をパス／コミット単位で特定（テンプレと同名パスが理想）
2. `yellow-seed/template` を clone するか、**別 worktree** で作業ブランチを切る
3. 取り込み方を選ぶ  
   - **cherry-pick**: コミットがそのまま通用するとき  
   - **パッチ適用・手動コピー**: パスや文言の抽象化が必要なとき。派生固有部分を削ってから載せる
4. template 向け PR を作る。**本文に出典**（派生リポ URL・ベースコミット SHA・要点）を書くと追跡しやすい
5. マージ後、各派生は通常の **Pull** で追随する

**載せないことが多いもの**: アプリ固有の依存バージョン、環境変数の値、製品ドメインに結びついた README、組織だけの運用。

## 事前に読むリポジトリの様子（Pull / Push 共通）

```bash
ls package.json pyproject.toml Cargo.toml go.mod Gemfile 2>/dev/null
ls -la .github .agents .claude .codex .Codex .cursor scripts .githooks 2>/dev/null
```

## チェックリスト

**Pull（派生がテンプレを取り込む）**

- [ ] `template/main`（または対象 SHA）を取得した
- [ ] 適用範囲を選び、スタックに合わない変更を除外した
- [ ] コミット／PR にテンプレ側の参照（SHA など）を残した
- [ ] CI またはローカルで最低限の確認をした

**Push（派生からテンプレへ）**

- [ ] 秘密・固有名・環境依存を除いた
- [ ] template 用ブランチでレビュー可能な単位にした
- [ ] PR に出典リポジトリとコミットを書いた
- [ ] マージ後に派生への追随タスクがわかるようにした（Issue / 運用メモなど）

## トラブルシューティング

| 状況 | 対処 |
|------|------|
| テンプレに fetch できない | SSH／HTTPS の切り替え、`git ls-remote` で認証確認 |
| 差分が大きすぎる | ディレクトリやテーマごとに PR を分割 |
| マージが難しい | ツール側の構造だけ先に揃え、中身は手動調整。Push のときはコミットを分割してから cherry-pick |

## 他のスキルとの連携

- **commit-message**: 同期コミットは `chore:` / `docs:` / `ci:` などにし、テンプレ由来なら本文で明示
- **pull-request**: 大量変更は PR で。Push 型はテンプレ側 PR が本体
- **github-issue**: 取り込めなかった項目や定期追随を記録

## 既定のテンプレ情報

- **リポジトリ**: `yellow-seed/template`
- **ブランチ**: `main`
- **URL**: `https://github.com/yellow-seed/template.git`

別テンプレートを参照するときは環境変数で上書きする。

```bash
export TEMPLATE_REPO="https://github.com/your-org/your-template.git"
```
