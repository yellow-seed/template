# Shell Script Linting

このプロジェクトでは、shellcheck と shfmt を使用してシェルスクリプトの品質を保証しています。

## ツール

- **shellcheck**: Bash/sh スクリプトの静的解析ツール
- **shfmt**: シェルスクリプトのフォーマッター（インデント: 2スペース）

## ローカルでの実行

### Docker を使用

```bash
# Docker イメージのビルド
docker build -f Dockerfile.shell-linting -t shell-linting .

# Docker Compose で実行
docker-compose -f docker-compose.shell-linting.yml run shell-linting

# または、docker run で実行
docker run --rm -v $(pwd):/workspace shell-linting
```

### 直接実行（ツールをインストール済みの場合）

```bash
# shellcheck を実行
find . -name "*.sh" -type f -print0 | xargs -0 shellcheck --severity=warning

# shfmt でフォーマットチェック
find . -name "*.sh" -type f -print0 | xargs -0 shfmt -i 2 -ci -bn -d

# shfmt でフォーマット自動修正
find . -name "*.sh" -type f -print0 | xargs -0 shfmt -i 2 -ci -bn -w
```

## CI/CD

GitHub Actions の `.github/workflows/shell-linting.yml` で自動実行されます:

- Pull Request 時: `.sh` ファイルの変更時に自動実行
- Push 時: main ブランチへのプッシュ時に実行
- 手動実行: workflow_dispatch で実行可能

## GitHub Copilot との統合

`.github/workflows/copilot-setup-steps.yml` でも同等のリンティング環境が利用可能です。

## 詳細

詳細なチェック項目やベストプラクティスについては、`.claude/skills/shell-linting/SKILL.md` を参照してください。
