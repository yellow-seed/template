---
name: design-plan
description: "設計計画スキル。TDD開発前の設計フェーズを支援し、仕様ドキュメントを作成。Use when: 新機能・API・画面・インフラの設計、実装前の仕様策定を依頼された時。"
---

# 設計計画（Design Plan）

TDD開発を開始する前の設計フェーズを支援します。実装前に設計仕様を文書化し、この仕様を元にtest-driven-developmentスキルで実装を開始できる状態を作ります。

## ワークフロー

```
1. design-plan スキル実行
   ↓ 設計ドキュメント作成 (docs/design/ 配下)
2. 補助ツールでの設計レビュー
   ↓ Swagger UI, Storybook, Terraform plan 等で確認
3. test-driven-development スキル実行
   ↓ Red-Green-Refactor サイクル
4. 実装完了
```

## 開発タイプ別ガイド

このスキルは5つの開発タイプをサポートしています。詳細は各リンク先を参照してください。

### 1. CLI開発

コマンドライン インターフェース の設計

**補助ツール**: --help, man, CLIフレームワーク (oclif, cobra, clap, click等)

→ **詳細**: [resources/cli_design_desc.md](./resources/cli_design_desc.md)

### 2. API開発

RESTful API または GraphQL API の設計

**補助ツール（基本）**: **Swagger UI / OpenAPI Specification**

→ **詳細**: [resources/api_design_desc.md](./resources/api_design_desc.md)

### 3. 画面開発（Web/フロントエンド）

Webアプリケーション の UI/UX 設計

**補助ツール（基本）**: **Storybook**

→ **詳細**: [resources/ui_design_desc.md](./resources/ui_design_desc.md)

### 4. モバイルアプリ開発

iOS/Android モバイルアプリ の設計

**補助ツール**: Figma, React Native Storybook, Flutter DevTools/Widgetbook

→ **詳細**: [resources/mobile_design_desc.md](./resources/mobile_design_desc.md)

### 5. クラウドインフラ構築

AWS/Azure/GCP などのクラウドインフラ設計

**補助ツール（基本）**: **Terraform / OpenTofu**

→ **詳細**: [resources/infrastructure_design_desc.md](./resources/infrastructure_design_desc.md)

## 設計ドキュメントの配置

```
docs/design/
├── README.md                           # 設計ドキュメント全体の概要
├── [type]-specification.md             # 各タイプの仕様書
└── [補助ツールの設定ファイル]          # openapi.yaml, terraform/ 等
```

詳細なディレクトリ構造は [REFERENCE.md](./REFERENCE.md) を参照してください。

## クイックスタート

### API設計の例

```bash
mkdir -p docs/design
touch docs/design/openapi.yaml
# API仕様を記述（resources/api_design_desc.md 参照）
npx @stoplight/prism-cli mock docs/design/openapi.yaml
```

### 画面設計の例

```bash
touch docs/design/ui-specification.md
npx storybook@latest init
npm run storybook
```

### インフラ設計の例

```bash
mkdir -p docs/design/terraform
# Terraform設定を記述（resources/infrastructure_design_desc.md 参照）
cd docs/design/terraform
terraform init
terraform plan
```

## 詳細情報

より詳細な情報は [REFERENCE.md](./REFERENCE.md) を参照してください：

- 設計計画の目的と原則
- 設計フェーズの実施手順
- 設計品質チェックポイント
- 他のスキルとの連携
- 補助ツールの選定基準
- カスタマイズとプロジェクト固有の調整
- 注意事項とFAQ

---

**次のステップ**: 設計完了後は [test-driven-development](../test-driven-development/SKILL.md) スキルで実装を開始してください。
