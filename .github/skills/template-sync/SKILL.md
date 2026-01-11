---
name: template-sync
description: "テンプレート同期スキル。yellow-seed/template の更新を他のリポジトリに反映。Use when: テンプレート更新の反映、template同期、既存リポジトリへの変更適用を依頼された時。"
---

# テンプレート同期

yellow-seed/template の更新内容を、このテンプレートを基に作成された他のリポジトリに反映するためのスキルです。

## 背景

- yellow-seed/template はテンプレート用途で、新しいリポジトリ作成時のベースとして使用される
- yellow-seed/template を更新した際、これを基にした既存リポジトリにも変更を追随させたい
- 多くのリポジトリが yellow-seed/template をベースにしているため、効率的な同期メカニズムが必要

## 同期原則

1. **非破壊的**: 参照先リポジトリの既存設定を尊重
2. **選択的適用**: 必要な変更のみを適用
3. **カスタマイズ保持**: プロジェクト固有のカスタマイズを保護
4. **透明性**: 適用される変更を明確に説明
5. **安全性**: 適用前に確認プロセスを提供

## 同期可能な要素

| 要素 | ファイルパス | 同期戦略 |
| ----- | ------------- | ------------- |
| GitHub設定全般 | `.github/` | **全ての内容をベース**として使用。新規ファイル・ディレクトリを追加、既存は保持 |
| ├─ Workflows | `.github/workflows/` | 新規ワークフローを追加、既存は保持 |
| ├─ Issueテンプレート | `.github/ISSUE_TEMPLATE/` | 新規テンプレートを追加、既存は保持 |
| ├─ PRテンプレート | `.github/PULL_REQUEST_TEMPLATE.md` | 新規追加、既存は保持 |
| └─ その他（将来追加） | `.github/skills/`, `.github/configs/`等 | 新規ディレクトリ・ファイルを自動的に追加 |
| Skills | `.claude/skills/` | 新規skillを追加、既存は保持 |
| Hooks | `.claude/hooks/` | 新規hookを追加、既存は更新確認 |
| ドキュメント | `AGENTS.md`, `CLAUDE.md` | セクション単位でマージ |
| コーディング規約 | `.editorconfig`, `.eslintrc`等 | 競合時はユーザー確認 |
| Git設定 | `.gitignore`, `.gitattributes` | 行単位でマージ |

**重要**: `.github/` 配下は将来的に新しいディレクトリやファイルが追加される可能性があります（例: `.github/skills/`, `.github/configs/` など）。これらは全て自動的に同期対象となり、yellow-seed/template から他のリポジトリへ反映されます。

## 同期手順

### 1. yellow-seed/template の情報確認

```bash
# yellow-seed/template のURL（デフォルト）
TEMPLATE_REPO="https://github.com/yellow-seed/template.git"

# yellow-seed/template の最新情報を取得
git ls-remote --heads $TEMPLATE_REPO
```

### 2. 現在のリポジトリ設定を分析

**分析項目**:
- プログラミング言語とフレームワーク
- 既存のCI/CD設定
- プロジェクト構造
- カスタマイズされた設定ファイル
- 既存のskillsとhooks

**分析方法**:
```bash
# 言語検出
ls package.json pyproject.toml Cargo.toml go.mod Gemfile pom.xml build.gradle 2>/dev/null

# 既存のskills確認
ls -la .claude/skills/ 2>/dev/null

# 既存の.github/設定確認（全体）
ls -la .github/ 2>/dev/null
find .github/ -type f 2>/dev/null

# 既存のドキュメント確認
ls AGENTS.md CLAUDE.md README.md 2>/dev/null
```

### 3. yellow-seed/template との差分を検出

```bash
# yellow-seed/template をリモートとして追加（一時的）
git remote add template $TEMPLATE_REPO 2>/dev/null || true
git fetch template main

# 差分を確認
git diff HEAD template/main --name-only

# 特定ディレクトリの差分を詳細確認
git diff HEAD template/main -- .claude/skills/
git diff HEAD template/main -- .github/
git diff HEAD template/main -- AGENTS.md
```

### 4. 適用すべき変更を選択

**自動適用可能な変更**:
- `.claude/skills/`内の新規skillファイル
- `.github/`配下の全ての新規ファイル・ディレクトリ
  - `.github/workflows/`内の新規ワークフローファイル
  - `.github/ISSUE_TEMPLATE/`内の新規テンプレート
  - `.github/skills/`, `.github/configs/`等、将来追加される新規ディレクトリ

**確認が必要な変更**:
- 既存ファイルの更新
- 設定ファイルの変更（`.gitignore`, `.editorconfig`等）
- ドキュメントファイルの更新（`AGENTS.md`, `CLAUDE.md`）

**適用しない変更**:
- プロジェクト固有のファイル（`README.md`のプロジェクト名等）
- カスタマイズされた設定
- プロジェクト固有のworkflows

### 5. 変更内容の微調整

#### 5.1 言語・フレームワーク固有の調整

```bash
# 例: Node.jsプロジェクトの場合
if [ -f "package.json" ]; then
  # Node.js関連のworkflowsのみ適用
  # Python関連のworkflowsはスキップ
fi
```

#### 5.2 既存設定との統合

**戦略**:
- 新規ファイル: そのまま追加
- 既存ファイルの新規セクション: セクション単位で追加
- 既存ファイルの更新: ユーザーに確認を求める

**例: AGENTS.mdの統合**:
```markdown
# 現在のAGENTS.md
## プロジェクト概要
[既存の内容]

# yellow-seed/template からの新規セクション
## 開発環境のセットアップ
### Claude Code での GitHub CLI (gh) のセットアップ
[新規内容を追加]
```

#### 5.3 競合解決

**競合が発生する場合**:
1. 両方の内容を並べて表示
2. 推奨される統合方法を提案
3. ユーザーの確認を待つ
4. ユーザーの選択に基づいて適用

### 6. 変更を適用

```bash
# yellow-seed/template の .github/workflows/new-workflow.yml を追加
git show template/main:.github/workflows/new-workflow.yml > .github/workflows/new-workflow.yml

# yellow-seed/template の .github/skills/ を追加する例
mkdir -p .github/skills
git archive --remote=$TEMPLATE_REPO HEAD:.github/skills/ | tar -x -C .github/skills/

# yellow-seed/template の .claude/skills/new-skill/SKILL.md を追加
git show template/main:.claude/skills/new-skill/SKILL.md > .claude/skills/new-skill/SKILL.md

# ドキュメントの部分更新例（セクション追加）
# 手動でセクションを追加、または既存内容を保持してマージ
```

### 7. 適用結果の確認

```bash
# 変更内容を確認
git status
git diff

# 変更をコミット
git add .
git commit -m "chore: sync updates from yellow-seed/template

Applied changes:
- Added new skill: xxx
- Added new workflow: yyy
- Updated AGENTS.md with new sections

Source: yellow-seed/template@<commit-hash>"
```

### 8. クリーンアップ

```bash
# 一時的に追加したリモートを削除
git remote remove template
```

## 実行例

### シナリオ1: 新規skillの追加

```markdown
**検出された変更**:
- yellow-seed/template の `.claude/skills/template-sync/SKILL.md` (新規)

**適用戦略**:
- このファイルは新規skillなので、そのまま追加可能

**実行**:
1. ディレクトリ作成: `mkdir -p .claude/skills/template-sync`
2. ファイルコピー: yellow-seed/template から内容を取得
3. コミット: `git commit -m "chore: add template-sync skill from yellow-seed/template"`
```

### シナリオ2: GitHub Actionsワークフローの追加

```markdown
**検出された変更**:
- yellow-seed/template の `.github/workflows/shell-linting.yml` (新規)

**適用戦略**:
- このプロジェクトはシェルスクリプトを含むため、このワークフローは有用
- そのまま追加可能

**実行**:
1. ファイルコピー: yellow-seed/template から取得
2. 動作確認: ワークフローの設定が現在のリポジトリに適合するか確認
3. コミット: `git commit -m "chore: add shell linting workflow from yellow-seed/template"`
```

### シナリオ2-2: .github/配下の新規ディレクトリ追加（将来的な例）

```markdown
**検出された変更**:
- yellow-seed/template の `.github/skills/` (新規ディレクトリ)
  - yellow-seed/template の `.github/skills/auto-review.yml`
  - yellow-seed/template の `.github/skills/auto-label.yml`

**適用戦略**:
- `.github/`配下の全ての内容はベースとして使用
- 新規ディレクトリとその内容を自動的に追加

**実行**:
1. ディレクトリ作成: `mkdir -p .github/skills`
2. ファイルコピー: yellow-seed/template から全ファイルを取得
3. 動作確認: 設定が現在のリポジトリに適合するか確認
4. コミット: `git commit -m "chore: add GitHub skills from yellow-seed/template"`
```

### シナリオ3: AGENTS.mdの更新

```markdown
**検出された変更**:
- yellow-seed/template の `AGENTS.md`: 新規セクション「開発環境のセットアップ」

**適用戦略**:
- 既存のAGENTS.mdに新規セクションを追加
- プロジェクト固有の内容は保持

**実行**:
1. 現在のAGENTS.mdを読み込み
2. 新規セクションを適切な位置に挿入
3. フォーマット調整
4. コミット: `git commit -m "docs: add development setup section from yellow-seed/template"`
```

### シナリオ4: 競合が発生する場合

```markdown
**検出された変更**:
- yellow-seed/template の `.gitignore`: 複数の新規エントリ

**現在の.gitignore**:
```
node_modules/
.env
dist/
```

**yellow-seed/template の .gitignore**:
```
# Node
node_modules/
.env
dist/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Claude Code
.claude/settings.local.json
```

**適用戦略**:
- 新規セクション（IDE, OS, Claude Code）を追加
- 既存エントリは保持

**実行**:
1. `.gitignore`に新規セクションを追加
2. 既存の内容は変更しない
3. コミット: `git commit -m "chore: update .gitignore from yellow-seed/template"`
```

## 同期時のチェックリスト

- [ ] yellow-seed/template の最新情報を取得した
- [ ] 現在のリポジトリの設定を分析した
- [ ] 差分を確認し、適用すべき変更を選択した
- [ ] プロジェクト固有の設定を保持する戦略を確認した
- [ ] 新規ファイルの追加を実行した
- [ ] 既存ファイルの更新（必要な場合）をユーザーと確認した
- [ ] 変更内容をコミットした
- [ ] 一時的なリモートをクリーンアップした
- [ ] 適用後の動作確認を行った

## 注意事項

1. **バックアップの推奨**: 同期前にブランチを作成することを推奨
   ```bash
   git checkout -b sync-from-template
   ```

2. **段階的な適用**: 一度に全ての変更を適用せず、段階的に適用することを推奨

3. **テストの実施**: 適用後、必ずCI/CDやローカルテストを実施

4. **ドキュメントの確認**: READMEやAGENTS.mdの内容がプロジェクトに適合しているか確認

5. **カスタマイズの尊重**: プロジェクト固有のカスタマイズは常に尊重

## トラブルシューティング

### 問題: yellow-seed/template にアクセスできない

**解決策**:
```bash
# SSHキーの確認
ssh -T git@github.com

# HTTPSでアクセスを試す
TEMPLATE_REPO="https://github.com/yellow-seed/template.git"
```

### 問題: 差分が大きすぎて適用が困難

**解決策**:
- 優先度の高い変更のみを適用
- 複数のPRに分割して段階的に適用

### 問題: 競合が複雑で自動マージが困難

**解決策**:
- ユーザーに手動マージを依頼
- 競合部分の両方の内容を表示し、選択を促す

## 他のスキルとの連携

### commit-message スキルとの連携

- 同期によるコミットは `chore:` タイプを使用
- コミットメッセージに yellow-seed/template のコミットハッシュを含める

### pull-request スキルとの連携

- 大規模な同期の場合、PRを作成して変更をレビュー
- PR概要で yellow-seed/template からの変更内容を明確に説明

### github-issue スキルとの連携

- 適用できなかった変更や要検討事項をIssueとして記録
- yellow-seed/template 同期の定期実施をtodoとして管理

## ベストプラクティス

1. **定期的な同期**: yellow-seed/template の更新を定期的にチェック
2. **選択的適用**: 全ての変更を盲目的に適用せず、必要なもののみを選択
3. **ドキュメント化**: 適用した変更と理由をドキュメント化
4. **テスト重視**: 適用後は必ずテストを実施
5. **コミュニティ貢献**: yellow-seed/template への改善提案も検討

## 実装の最小化

このskillは以下の最小限のセットアップで動作します：

1. **必須ファイル**: このSKILL.mdファイルのみ
2. **依存関係**: Git、GitHub CLI（gh）
3. **設定**: 環境変数 `TEMPLATE_REPO`（オプション、デフォルト: yellow-seed/template）

**使用方法**:
```bash
# AI Agentに依頼するだけ
"yellow-seed/template の最新の変更を同期してください"
```

AI Agentが自動的に：
1. yellow-seed/template の変更を検出
2. 現在のリポジトリ設定を分析
3. 適用可能な変更を提案
4. ユーザーの確認後、変更を適用
5. 適切なコミットメッセージでコミット

## yellow-seed/template 情報

- **リポジトリ**: `yellow-seed/template`
- **ブランチ**: `main`
- **URL**: `https://github.com/yellow-seed/template.git`

別のテンプレートを使用する場合は、以下のように指定：
```bash
TEMPLATE_REPO="https://github.com/your-org/your-template.git"
```
