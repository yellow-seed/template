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
   ↓ 設計ドキュメント + 補助ツールの設定ファイル作成 (docs/配下)
2. 補助ツールでの設計レビュー・検証
   ↓ Swagger UI, Storybook, Terraform plan などで仕様を確認
3. test-driven-development スキル実行
   ↓ Red-Green-Refactor サイクル
4. 実装完了
```

## 開発タイプ別の設計ガイドライン

### 1. CLI開発: コマンド仕様

#### 作成する設計ドキュメント

`docs/design/cli-specification.md` を作成:

- **コマンド概要**: コマンドの目的と基本的な使い方
- **コマンド構文**: `command [options] <arguments>`
- **引数**: 必須引数と任意引数の説明
- **オプション**: フラグとその動作
- **入出力例**: 具体的な使用例と期待される出力
- **エラーケース**: エラーメッセージと終了コード
- **使用例とユースケース**: 典型的な使用シナリオ

#### 補助ツールと設定ファイル

- **--help 出力仕様**: ヘルプメッセージの設計
- **man ページ形式**: 詳細なドキュメント構造
- **CLIフレームワークのスキーマ**:
  - Node.js: `oclif`, `commander.js`
  - Go: `cobra`, `cli`
  - Rust: `clap`
  - Python: `argparse`, `click`

#### テンプレート構成例

```markdown
# CLI仕様: [コマンド名]

## 概要
[コマンドの目的と基本的な使い方]

## 構文
\`\`\`
command [options] <arguments>
\`\`\`

## 引数
- `<arg1>`: [説明]
- `[arg2]`: [説明]（任意）

## オプション
- `-f, --flag`: [説明]
- `-o, --output <file>`: [説明]

## 使用例
\`\`\`bash
# 基本的な使用例
command input.txt

# オプション付き
command -f -o output.txt input.txt
\`\`\`

## 期待される出力
\`\`\`
[出力例]
\`\`\`

## エラーケース
- ファイルが見つからない: `Error: File not found: input.txt` (exit code: 1)
- 権限エラー: `Error: Permission denied` (exit code: 2)

## 終了コード
- 0: 正常終了
- 1: ファイルエラー
- 2: 権限エラー
```

---

### 2. API開発: API仕様

#### 作成する設計ドキュメント

`docs/design/api-specification.md` および OpenAPI仕様ファイルを作成:

- **エンドポイント一覧**: すべてのAPIエンドポイント
- **HTTPメソッド**: GET, POST, PUT, DELETE等
- **パス**: URLパターンとパスパラメータ
- **リクエスト形式**: ヘッダー、ボディ、パラメータ
- **レスポンス形式**: ステータスコード、ボディスキーマ
- **認証・認可**: 認証方法と必要な権限
- **エラーハンドリング**: エラーレスポンスの形式

#### 補助ツール（基本: Swagger UI / OpenAPI）

- **Swagger UI / OpenAPI Specification**: RESTful API仕様の定義と可視化（基本）
- **Postman Collections**: API テスト・ドキュメンテーション
- **API Blueprint**: APIドキュメント記述フォーマット
- **GraphQL Playground / GraphiQL**: GraphQL APIの場合
- **Stoplight Studio**: OpenAPIの視覚的エディタ

#### OpenAPI仕様ファイル例

`docs/design/openapi.yaml`:

```yaml
openapi: 3.0.0
info:
  title: [API名]
  version: 1.0.0
  description: [API説明]
servers:
  - url: https://api.example.com/v1
paths:
  /users:
    get:
      summary: ユーザー一覧を取得
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 10
      responses:
        '200':
          description: 成功
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
    post:
      summary: ユーザーを作成
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserInput'
      responses:
        '201':
          description: 作成成功
        '400':
          description: バリデーションエラー
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: integer
        name:
          type: string
        email:
          type: string
    UserInput:
      type: object
      required:
        - name
        - email
      properties:
        name:
          type: string
        email:
          type: string
```

#### Swagger UIのセットアップ

`docs/design/README.md`:

```markdown
# API設計ドキュメント

## Swagger UIでの確認

\`\`\`bash
# Swagger UIをローカルで起動
npx @stoplight/prism-cli mock openapi.yaml
# または
docker run -p 8080:8080 -v $(pwd):/usr/share/nginx/html/api swaggerapi/swagger-ui
\`\`\`

ブラウザで http://localhost:8080 を開く
```

---

### 3. 画面開発（Web/フロントエンド）: UI/UX仕様

#### 作成する設計ドキュメント

`docs/design/ui-specification.md` を作成:

- **画面構成**: ページレイアウトとセクション
- **コンポーネント構造**: UIコンポーネントの階層
- **状態管理**: アプリケーション状態とデータフロー
- **ユーザーインタラクション**: クリック、入力などのイベント
- **レスポンシブデザイン**: ブレークポイントとレイアウト変更
- **アクセシビリティ**: ARIA属性、キーボード操作

#### 補助ツール（基本: Storybook）

- **Storybook**: コンポーネントカタログとUI開発環境（基本）
- **Figma / Adobe XD**: デザインモックアップとプロトタイプ
- **Chromatic**: ビジュアルレグレッションテスト
- **Zeplin**: デザインとコードの橋渡し
- **Histoire**: Vite向けの軽量Storybook代替

#### Storybookのセットアップ

`docs/design/storybook-setup.md`:

```markdown
# Storybook セットアップ

## インストール

\`\`\`bash
npx storybook@latest init
\`\`\`

## コンポーネント例

\`src/components/Button.stories.tsx\`:

\`\`\`typescript
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: {
    variant: 'primary',
    children: 'Primary Button',
  },
};

export const Secondary: Story = {
  args: {
    variant: 'secondary',
    children: 'Secondary Button',
  },
};
\`\`\`

## 起動

\`\`\`bash
npm run storybook
\`\`\`
```

#### UI仕様テンプレート

```markdown
# UI仕様: [画面名]

## 概要
[画面の目的と主要機能]

## コンポーネント構造
\`\`\`
Page
├── Header
│   ├── Logo
│   └── Navigation
├── MainContent
│   ├── Sidebar
│   └── ContentArea
└── Footer
\`\`\`

## 状態管理
- **ローカル状態**: [コンポーネント内の状態]
- **グローバル状態**: [アプリケーション全体の状態]

## ユーザーインタラクション
1. ボタンクリック → [動作]
2. フォーム入力 → [バリデーション]
3. ページ遷移 → [遷移先]

## レスポンシブデザイン
- モバイル (< 768px): [レイアウト]
- タブレット (768px - 1024px): [レイアウト]
- デスクトップ (> 1024px): [レイアウト]

## アクセシビリティ
- キーボード操作: Tab, Enter, Escapeで操作可能
- ARIA属性: role, aria-label等を適切に設定
- コントラスト比: WCAG AA基準を満たす
```

---

### 4. モバイルアプリ開発: 画面・操作仕様

#### 作成する設計ドキュメント

`docs/design/mobile-specification.md` を作成:

- **画面遷移図**: 画面間の遷移とナビゲーション
- **各画面の操作フロー**: ユーザーの操作手順
- **UI要素とレイアウト**: ボタン、入力欄、リスト等
- **プラットフォーム固有の考慮事項**: iOS/Androidの差異
- **ジェスチャー**: スワイプ、ピンチ等のタッチジェスチャー
- **パフォーマンス**: 画面読み込み、アニメーション

#### 補助ツール

- **Figma / Adobe XD**: モバイルUIデザインとプロトタイプ
- **Proto.io / InVision**: インタラクティブプロトタイプ
- **Zeplin**: デザイン仕様の共有
- **React Native Storybook**: React Native用コンポーネントカタログ
- **Flutter DevTools / Widgetbook**: Flutter用UI開発ツール
- **Marvel / Framer**: プロトタイピングツール

#### モバイルUI仕様テンプレート

```markdown
# モバイルUI仕様: [アプリ名]

## 画面遷移図

\`\`\`
スプラッシュ画面
  ↓
ログイン画面
  ↓
ホーム画面
  ├→ プロフィール画面
  ├→ 設定画面
  └→ 詳細画面
\`\`\`

## 画面仕様

### ホーム画面

**レイアウト**:
- ヘッダー: タイトル、通知アイコン
- コンテンツエリア: スクロール可能なリスト
- フッター: ナビゲーションタブ

**操作**:
1. リストアイテムをタップ → 詳細画面へ遷移
2. 通知アイコンをタップ → 通知一覧を表示
3. 下にスワイプ → リフレッシュ

**ジェスチャー**:
- タップ: アイテム選択
- スワイプダウン: リフレッシュ
- スワイプレフト: アイテム削除

**プラットフォーム差異**:
- iOS: ネイティブナビゲーションバー
- Android: マテリアルデザインのAppBar

## パフォーマンス要件
- 画面読み込み: 1秒以内
- アニメーション: 60fps維持
```

---

### 5. クラウドインフラ構築: インフラ設計

#### 作成する設計ドキュメント

`docs/design/infrastructure-specification.md` および IaCファイルを作成:

- **システムアーキテクチャ図**: 全体構成の俯瞰図
- **リソース構成**: コンピュート、ストレージ、データベース等
- **ネットワーク設計**: VPC、サブネット、ルーティング
- **セキュリティ設計**: IAM、セキュリティグループ、暗号化
- **可用性・スケーラビリティ**: 冗長化、オートスケーリング
- **コスト見積もり**: 月額コストの試算
- **運用・監視設計**: ログ、メトリクス、アラート

#### 補助ツール（基本: Terraform / OpenTofu）

**IaC（Infrastructure as Code）ツール**:
- **Terraform / OpenTofu**: マルチクラウド対応IaC（基本）
- **AWS CloudFormation / AWS CDK**: AWS特化のIaC
- **Azure Resource Manager (ARM) / Bicep**: Azure特化のIaC
- **Google Cloud Deployment Manager**: GCP特化のIaC
- **Pulumi**: 複数プログラミング言語対応のIaC

**アーキテクチャ図作成**:
- **Diagrams (Python diagrams)**: コードベースのアーキテクチャ図生成
- **Cloudcraft**: AWS/Azure/GCPアーキテクチャ図作成
- **draw.io / Lucidchart**: 汎用的なアーキテクチャ図作成

**検証・分析ツール**:
- **Checkov / tfsec / terrascan**: IaCセキュリティスキャン
- **Infracost**: クラウドコスト見積もり
- **Terraform Docs**: Terraformドキュメント自動生成
- **Rover**: Terraformの可視化ツール

#### Terraform設計例

`docs/design/terraform/main.tf`:

```hcl
# VPC設定
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc"
    Environment = "production"
  }
}

# パブリックサブネット
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# セキュリティグループ
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-security-group"
  }
}
```

#### アーキテクチャ図生成例（Python Diagrams）

`docs/design/architecture_diagram.py`:

```python
from diagrams import Diagram, Cluster
from diagrams.aws.compute import EC2
from diagrams.aws.network import ELB, VPC
from diagrams.aws.database import RDS

with Diagram("Web Service Architecture", show=False):
    with Cluster("VPC"):
        with Cluster("Public Subnet"):
            lb = ELB("Load Balancer")
            web_servers = [EC2("Web 1"), EC2("Web 2")]

        with Cluster("Private Subnet"):
            db = RDS("Database")

    lb >> web_servers >> db
```

実行:
```bash
python architecture_diagram.py
```

#### インフラ仕様テンプレート

```markdown
# インフラ仕様: [プロジェクト名]

## システムアーキテクチャ概要
[全体構成の説明]

## リソース構成

### コンピュート
- EC2 インスタンス: t3.medium × 2
- Auto Scaling: 最小2、最大10
- ECS/Fargate: コンテナ実行環境

### ストレージ
- S3: 静的ファイル、バックアップ
- EBS: 永続ボリューム

### データベース
- RDS (PostgreSQL): マスター/リードレプリカ構成
- ElastiCache (Redis): セッション・キャッシュ

## ネットワーク設計

### VPC
- CIDR: 10.0.0.0/16
- アベイラビリティーゾーン: 2 AZ構成

### サブネット
- パブリックサブネット: 10.0.0.0/24, 10.0.1.0/24
- プライベートサブネット: 10.0.10.0/24, 10.0.11.0/24

## セキュリティ設計

### IAM
- 最小権限の原則
- ロールベースのアクセス制御

### セキュリティグループ
- Web: 80, 443ポートを公開
- App: Webからのみアクセス可
- DB: Appからのみアクセス可

### 暗号化
- データ転送: TLS 1.2以上
- データ保管: S3/EBS暗号化

## 可用性・スケーラビリティ

### 高可用性
- マルチAZ構成
- ロードバランサー

### スケーラビリティ
- Auto Scaling (CPU使用率70%でスケールアウト)
- データベースリードレプリカ

## コスト見積もり

| リソース | 月額コスト（USD） |
|----------|-------------------|
| EC2 (t3.medium × 2) | $60 |
| RDS (db.t3.medium) | $50 |
| ALB | $20 |
| S3 | $10 |
| **合計** | **$140** |

## 運用・監視

### ログ
- CloudWatch Logs: アプリケーションログ
- VPC Flow Logs: ネットワークトラフィック

### メトリクス
- CPU使用率
- メモリ使用率
- ディスクI/O

### アラート
- CPU使用率 > 80%
- エラーレート > 5%
```

---

## 設計ドキュメントの配置

### ディレクトリ構造

```
docs/
└── design/
    ├── README.md                    # 設計ドキュメント全体の概要
    ├── cli-specification.md         # CLI仕様
    ├── api-specification.md         # API仕様
    ├── openapi.yaml                 # OpenAPI仕様ファイル
    ├── ui-specification.md          # UI/UX仕様
    ├── mobile-specification.md      # モバイルUI仕様
    ├── infrastructure-specification.md  # インフラ仕様
    ├── storybook-setup.md           # Storybookセットアップ
    └── terraform/                   # Terraformファイル
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

- 該当する開発タイプのテンプレートを使用
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

## 設計品質チェックポイント

| 項目 | チェック内容 |
|------|--------------|
| **完全性** | すべての機能・要件が設計に含まれているか |
| **明確性** | 曖昧さがなく、実装者が理解できるか |
| **テスタビリティ** | テストケースを導出できる設計か |
| **一貫性** | 命名規則、スタイルが統一されているか |
| **実現可能性** | 技術的に実装可能な設計か |
| **拡張性** | 将来の変更に対応しやすい設計か |
| **セキュリティ** | セキュリティリスクが考慮されているか |
| **パフォーマンス** | パフォーマンス要件を満たせる設計か |

## 他のスキルとの連携

### test-driven-development スキルとの連携

- **設計 → TDD**: 設計ドキュメントを元にテストケースを作成
- **Redフェーズ**: 設計仕様から失敗するテストを書く
- **Greenフェーズ**: 設計に従って実装
- **Refactorフェーズ**: 設計原則に基づいてリファクタリング

### github-issue スキルとの連携

- **Issue → 設計**: Issueの要件を設計ドキュメントに落とし込む
- **受け入れ基準**: 設計ドキュメントから受け入れ基準を明確化

### pull-request スキルとの連携

- **設計の変更**: PRで設計ドキュメントの変更も含める
- **レビュー**: 設計と実装の整合性を確認

## 補助ツールの選定基準

1. **オープンソース**: 可能な限りOSSツールを優先
2. **業界標準**: 広く採用されている実績のあるツール
3. **ドキュメント品質**: 十分なドキュメントとコミュニティサポート
4. **CI/CD統合**: 自動化とテストに組み込みやすい
5. **プロジェクト適合性**: チームのスキルセットと要件に合致

## カスタマイズとプロジェクト固有の調整

このスキルは基本的な設計ドキュメント構造と推奨補助ツールを提供します。各プロジェクトで以下をカスタマイズしてください：

1. **ドキュメント構造**: `docs/` ディレクトリ配下の構成
2. **補助ツールの選択**: プロジェクトに最適なツールを選定
3. **テンプレートの拡張**: プロジェクト固有の要件を追加
4. **ツールチェーン統合**: 既存の開発環境との統合

## 注意事項

1. **過度な設計を避ける**: 必要十分な設計にとどめ、実装中に詳細化
2. **設計と実装の同期**: 実装で設計を変更した場合はドキュメントを更新
3. **補助ツールの学習コスト**: チームの習熟度に応じてツールを選択
4. **設計レビューの重要性**: 実装前に必ず設計をレビュー
