# Pull Request Skill Test Checklist

このチェックリストは、Pull Request作成スキル (.claude/skills/pull-request/SKILL.md) が満たすべき要件を定義します。

## Issue #24 の受け入れ基準

- [ ] PR作成時のガイドラインが文書化されている
- [ ] AGENTS.md にPR概要作成の指針が記載されている（参照として）
- [ ] PRテンプレート（.github/pull_request_template.md）との連携が明確
- [ ] 良い例・悪い例の具体的なPR例が示されている
- [ ] AIエージェントがガイドラインに従ってPRを作成できる
- [ ] Summary、Changes、Test Plan のセクションが明確に定義されている

## 必須コンテンツ

### 1. PR概要のフォーマット定義

- [ ] **Summary** セクションの定義
  - 目的と背景を2-3文で記述する方法
  - 例: 「何を」「なぜ」「効果」を含む

- [ ] **Changes** セクションの定義
  - 変更内容を階層的に箇条書きする方法
  - ファイル単位、機能単位での構造化方法
  - 詳細説明の記述方法

- [ ] **Test Plan** セクションの定義
  - テスト方法と確認事項の記述方法
  - チェックリスト形式での記述例

- [ ] **Related Issues** セクションの定義
  - Issue参照の記述方法（Closes #XXX, Related to #YYY）

### 2. What/Why/How の明確化

- [ ] **What（何を変更したか）** の記述ガイド
- [ ] **Why（なぜ変更したか）** の記述ガイド
- [ ] **How（どのように変更したか）** の記述ガイド

### 3. レビュアー向け情報

- [ ] レビュアーが確認すべき点の記述ガイド
- [ ] 破壊的変更の明記方法

### 4. 良い例・悪い例

- [ ] **良い例** の提示
  - Issue #24に記載のシェルリンティング環境構築の例
  - Summary, Changes, Test Plan の実例

- [ ] **悪い例** の提示
  - 不十分なPRの例（"Add shell linting"など）
  - なぜ悪いのかの説明

### 5. AIエージェント向けガイド

- [ ] **コミット履歴からPR概要を生成する方法**
  ```bash
  git log main...HEAD --oneline
  git diff main...HEAD --name-only
  ```

- [ ] **各コミットメッセージから変更内容を抽出する方法**

- [ ] **変更ファイルごとにChangesセクションを構成する手順**

- [ ] **受け入れ基準をTest Planに変換する方法**

### 6. PR作成の実行手順

- [ ] PR作成前の確認事項
  - ブランチの状態確認（git status）
  - リモートへのpush確認

- [ ] PR作成コマンド
  ```bash
  gh pr create --title "..." --body "..."
  ```

- [ ] PR作成後の確認事項
  - PR URLの確認
  - CI/CDの実行確認

### 7. PR品質チェックポイント

- [ ] タイトルがConventional Commits形式に準拠
- [ ] Summaryが明確で簡潔（2-3文）
- [ ] Changesが構造化されている
- [ ] Test Planが具体的
- [ ] Related Issuesが正確

## 既存スキルとの整合性

他のスキル（commit-message, code-review, github-issue）との整合性:

- [ ] Conventional Commits形式との整合性（commit-messageスキルと連携）
- [ ] Issueテンプレートとの整合性（github-issueスキルと連携）
- [ ] コードレビューの観点との整合性（code-reviewスキルと連携）

## 実際の使用シナリオ検証

以下のシナリオでスキルが機能するか:

### シナリオ1: 新機能追加のPR

```bash
# ブランチ: feature/add-user-auth
# コミット履歴:
# - feat: add JWT authentication middleware
# - feat: add user login endpoint
# - test: add authentication tests
# - docs: update API documentation
```

- [ ] コミット履歴から適切なSummaryを生成できる
- [ ] 各コミットをChangesセクションにまとめられる
- [ ] テストコミットからTest Planを生成できる

### シナリオ2: バグ修正のPR

```bash
# ブランチ: fix/memory-leak
# コミット履歴:
# - fix: resolve memory leak in data processing
# - test: add memory leak regression test
```

- [ ] バグ修正の背景と原因をSummaryに記述できる
- [ ] 修正内容をChangesに明記できる
- [ ] 回帰テストをTest Planに記述できる

### シナリオ3: ドキュメント更新のPR

```bash
# ブランチ: docs/pr-guidelines
# コミット履歴:
# - docs: add PR creation skill documentation
# - docs: update AGENTS.md with PR guidelines
# - docs: update PR template
```

- [ ] ドキュメント更新の目的をSummaryに記述できる
- [ ] 各ドキュメントの変更内容をChangesに列挙できる

## テスト結果

- [ ] 全てのチェック項目をパスする .claude/skills/pull-request/SKILL.md が作成される
- [ ] Issue #24の受け入れ基準を全て満たす
- [ ] AIエージェントが実際にこのスキルを使ってPRを作成できる
