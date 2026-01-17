---
name: design-plan
description: "設計計画スキル。TDD開発前の設計フェーズを支援し、仕様ドキュメントを作成。Use when: 新機能・API・画面・インフラの設計、実装前の仕様策定を依頼された時。"
---

# 設計計画（Design Plan）

TDD開発を開始する前の設計フェーズを支援します。実装前に設計仕様を文書化し、この仕様を元にtest-driven-developmentスキルで実装を開始できる状態を作ります。

## 設計計画の目的

1. **実装の方向性を明確化**: テストや実装を始める前に要件を整理
2. **TDDの効率向上**: 設計仕様を元にテストケースを網羅的に作成可能
3. **ドキュメントの充実**: 実装と同時に設計ドキュメントが蓄積される
4. **レビューの容易化**: 設計レビュー → 実装レビューと段階的に確認可能
5. **補助ツールとの連携**: 各種ツールで設計を可視化・検証可能

## 設計計画の原則

1. **開発タイプに応じた設計**: CLI、API、画面、モバイル、インフラそれぞれに適した設計
2. **補助ツールの活用**: 業界標準のツールを使用して設計を可視化・検証
3. **テスタビリティ重視**: TDD実装を前提とした設計
4. **段階的な詳細化**: 初期は概要、必要に応じて詳細化
5. **プロジェクト固有のカスタマイズ**: 基本構造を提供し、各プロジェクトで調整可能

## ワークフロー

```
1. design-plan スキル実行
   ↓ 設計ドキュメント + 補助ツールの設定ファイル作成 (docs/design/ 配下)
2. 補助ツールでの設計レビュー・検証
   ↓ Swagger UI, Storybook, Terraform plan などで仕様を確認
3. test-driven-development スキル実行
   ↓ Red-Green-Refactor サイクル
4. 実装完了
```

## 開発タイプ別ガイド

このスキルは以下の5つの開発タイプをサポートしています。各タイプの詳細ガイドを参照してください。

### 1. CLI開発

コマンドライン インターフェース の設計

**作成するもの**:
- コマンド仕様（引数、オプション、入出力例）
- エラーケースとエラーメッセージ
- 使用例とユースケース

**補助ツール**:
- --help 出力仕様
- man ページ形式
- CLIフレームワーク (oclif, cobra, clap, click等)

**詳細**: [resources/cli_design_desc.md](./resources/cli_design_desc.md)

---

### 2. API開発

RESTful API または GraphQL API の設計

**作成するもの**:
- OpenAPI仕様ファイル
- エンドポイント一覧
- リクエスト/レスポンス形式
- 認証・認可の仕様

**補助ツール（基本）**:
- **Swagger UI / OpenAPI Specification**: RESTful API仕様の定義と可視化
- Postman Collections
- GraphQL Playground / GraphiQL

**詳細**: [resources/api_design_desc.md](./resources/api_design_desc.md)

---

### 3. 画面開発（Web/フロントエンド）

Webアプリケーション の UI/UX 設計

**作成するもの**:
- UI仕様書
- コンポーネント構造
- 状態管理設計
- レスポンシブデザイン仕様
- アクセシビリティ要件

**補助ツール（基本）**:
- **Storybook**: コンポーネントカタログとUI開発環境
- Figma / Adobe XD
- Chromatic

**詳細**: [resources/ui_design_desc.md](./resources/ui_design_desc.md)

---

### 4. モバイルアプリ開発

iOS/Android モバイルアプリ の設計

**作成するもの**:
- 画面遷移図
- 各画面の操作フロー
- UI要素とレイアウト
- プラットフォーム固有の考慮事項
- ジェスチャー操作仕様

**補助ツール**:
- Figma / Adobe XD
- React Native Storybook
- Flutter DevTools / Widgetbook

**詳細**: [resources/mobile_design_desc.md](./resources/mobile_design_desc.md)

---

### 5. クラウドインフラ構築

AWS/Azure/GCP などのクラウドインフラ設計

**作成するもの**:
- システムアーキテクチャ図
- リソース構成
- ネットワーク設計
- セキュリティ設計
- コスト見積もり

**補助ツール（基本）**:
- **Terraform / OpenTofu**: マルチクラウド対応IaC
- Diagrams (Python diagrams)
- Checkov / tfsec
- Infracost

**詳細**: [resources/infrastructure_design_desc.md](./resources/infrastructure_design_desc.md)

---

## 設計ドキュメントの配置

### ディレクトリ構造

```
docs/
└── design/
    ├── README.md                           # 設計ドキュメント全体の概要
    ├── cli-specification.md                # CLI仕様（該当する場合）
    ├── api-specification.md                # API仕様（該当する場合）
    ├── openapi.yaml                        # OpenAPI仕様ファイル（API開発の場合）
    ├── ui-specification.md                 # UI/UX仕様（画面開発の場合）
    ├── mobile-specification.md             # モバイルUI仕様（モバイル開発の場合）
    ├── infrastructure-specification.md     # インフラ仕様（インフラ構築の場合）
    ├── storybook-setup.md                  # Storybookセットアップ（画面開発の場合）
    ├── architecture_diagram.py             # アーキテクチャ図生成スクリプト（インフラの場合）
    └── terraform/                          # Terraformファイル（インフラの場合）
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 設計フェーズの実施手順

### 1. 要件の理解と分析

- Issue内容の確認
- 開発タイプの特定（CLI / API / 画面 / モバイル / インフラ）
- ステークホルダーの期待値確認

### 2. 設計ドキュメントの作成

- 該当する開発タイプのガイドを参照
- `docs/design/` 配下にドキュメントを作成
- 必要に応じて複数の開発タイプを組み合わせ

### 3. 補助ツールの設定

- OpenAPI仕様ファイルの作成（API開発の場合）
- Storybookのセットアップ（画面開発の場合）
- Terraformファイルの作成（インフラ構築の場合）
- その他、プロジェクトに応じた補助ツールの導入

### 4. 設計レビュー

- 補助ツールで設計を可視化
  - Swagger UIでAPIを確認
  - Storybookでコンポーネントを確認
  - `terraform plan`でインフラ変更を確認
- ステークホルダーとのレビュー
- フィードバックの反映

### 5. TDD実装への移行

- 設計ドキュメントを元にtest-driven-developmentスキルを実行
- Red-Green-Refactorサイクルで実装
- 設計と実装の乖離があれば設計ドキュメントを更新

## 補足情報

より詳細な情報は [REFERENCE.md](./REFERENCE.md) を参照してください：

- 設計品質チェックポイント
- 他のスキルとの連携
- 補助ツールの選定基準
- カスタマイズとプロジェクト固有の調整
- 注意事項

## クイックスタート

### API設計の例

```bash
# 1. OpenAPI仕様ファイルを作成
mkdir -p docs/design
touch docs/design/openapi.yaml

# 2. API仕様を記述（resources/api_design_desc.md 参照）

# 3. Swagger UIで確認
npx @stoplight/prism-cli mock docs/design/openapi.yaml
```

### インフラ設計の例

```bash
# 1. Terraformディレクトリを作成
mkdir -p docs/design/terraform

# 2. Terraform設定を記述（resources/infrastructure_design_desc.md 参照）

# 3. プラン確認
cd docs/design/terraform
terraform init
terraform plan
```

### 画面設計の例

```bash
# 1. UI仕様書を作成
touch docs/design/ui-specification.md

# 2. Storybookをセットアップ
npx storybook@latest init

# 3. Storybookを起動
npm run storybook
```

---

**次のステップ**: 設計完了後は [test-driven-development](../test-driven-development/SKILL.md) スキルで実装を開始してください。
