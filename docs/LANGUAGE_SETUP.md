# Language Setup Guide

このドキュメントでは、このプロジェクトで使用する各言語の基本構成について説明します。

## Ruby

### 必要なファイル

- `.ruby-version` - 使用するRubyのバージョンを指定
- `Gemfile` - 依存関係の管理
- `Gemfile.lock` - 依存関係のロックファイル（自動生成）

### 基本構成例

#### .ruby-version
```
3.2.0
```

#### Gemfile
```ruby
source 'https://rubygems.org'

ruby '3.2.0'

gem 'rails', '~> 7.0'
# その他のgem
```

### セットアップコマンド

```bash
# rbenvを使用する場合
rbenv install $(cat .ruby-version)

# Bundlerで依存関係をインストール
bundle install
```

### テストフレームワーク

- RSpec
- Minitest

## Python

### 必要なファイル

- `requirements.txt` - 依存関係の管理（pip用）
- `requirements-dev.txt` - 開発用依存関係（オプション）
- `pyproject.toml` - プロジェクト設定（PoetryやPipenvを使用する場合）
- `Pipfile` - Pipenvを使用する場合
- `.python-version` - pyenvを使用する場合

### 基本構成例

#### requirements.txt
```
requests>=2.28.0
flask>=2.3.0
pytest>=7.0.0
```

#### pyproject.toml (Poetry使用時)
```toml
[tool.poetry]
name = "project-name"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.11"
requests = "^2.28.0"

[tool.poetry.dev-dependencies]
pytest = "^7.0.0"
```

### セットアップコマンド

```bash
# 仮想環境を作成
python -m venv venv

# 仮想環境を有効化
source venv/bin/activate  # Linux/Mac
# または
venv\Scripts\activate  # Windows

# 依存関係をインストール
pip install -r requirements.txt
```

### テストフレームワーク

- pytest
- unittest

## JavaScript / TypeScript

### 必要なファイル

- `package.json` - プロジェクト設定と依存関係の管理
- `package-lock.json` - 依存関係のロックファイル（npm使用時、自動生成）
- `yarn.lock` - 依存関係のロックファイル（yarn使用時、自動生成）
- `tsconfig.json` - TypeScript設定（TypeScript使用時）
- `.nvmrc` - Node.jsバージョン指定（nvm使用時）

### 基本構成例

#### package.json
```json
{
  "name": "project-name",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "lint": "eslint .",
    "build": "tsc"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "jest": "^29.0.0",
    "eslint": "^8.0.0"
  }
}
```

#### tsconfig.json (TypeScript使用時)
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### セットアップコマンド

```bash
# npmを使用する場合
npm install

# yarnを使用する場合
yarn install

# pnpmを使用する場合
pnpm install
```

### テストフレームワーク

- Jest
- Mocha
- Vitest

### リンター/フォーマッター

- ESLint
- Prettier

## Go

### 必要なファイル

- `go.mod` - モジュール定義と依存関係の管理
- `go.sum` - 依存関係のチェックサム（自動生成）
- `.golangci.yml` - golangci-lint設定（オプション）

### 基本構成例

#### go.mod
```go
module github.com/your-username/project-name

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    // その他の依存関係
)
```

#### .golangci.yml (golangci-lint使用時)
```yaml
linters:
  enable:
    - errcheck
    - gofmt
    - goimports
    - govet
    - staticcheck

linters-settings:
  gofmt:
    simplify: true
```

### セットアップコマンド

```bash
# モジュールを初期化
go mod init github.com/your-username/project-name

# 依存関係をダウンロード
go mod download

# 依存関係を整理
go mod tidy
```

### テスト

Goの標準テストフレームワークを使用：

```bash
# テストを実行
go test ./...

# カバレッジを取得
go test -cover ./...
```

### リンター

- golangci-lint
- go vet
- staticcheck

## 共通のベストプラクティス

1. **バージョン管理**: 各言語のバージョンを明示的に指定する
2. **依存関係のロック**: ロックファイルをコミットに含める
3. **環境変数**: `.env`ファイルは`.gitignore`に含める
4. **テスト**: 各言語の標準的なテストフレームワークを使用する
5. **リンター**: コード品質を保つためにリンターを設定する
6. **CI/CD**: GitHub Actionsで各言語のテストとリンターを実行する

