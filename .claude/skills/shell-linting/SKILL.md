# Shell Script Linting

シェルスクリプトの品質を保証するための静的解析とフォーマットチェックを行います。

## 概要

このスキルは、shellcheck と shfmt を使用してシェルスクリプトの品質を確保します。

- **shellcheck**: Bash/sh スクリプトの静的解析ツール
- **shfmt**: シェルスクリプトのフォーマッター

## ツール詳細

### shellcheck

shellcheck は、シェルスクリプトの一般的なバグやアンチパターンを検出する静的解析ツールです。

#### 主なチェック項目

1. **変数の未定義参照**
   - 未定義変数の使用を検出
   - 変数のスコープミスを検出

2. **クォートの不足**
   - 変数展開時のクォート不足を検出
   - コマンド置換のクォート不足を検出

3. **コマンドの誤用**
   - 誤ったオプションの使用を検出
   - 非推奨のコマンドを検出

4. **条件式の誤り**
   - `[ ]` と `[[ ]]` の誤用を検出
   - 比較演算子の誤りを検出

5. **パイプラインとリダイレクトの問題**
   - 未使用のパイプを検出
   - リダイレクトの順序ミスを検出

6. **ポータビリティの問題**
   - Bash固有の機能の使用を検出
   - POSIX非互換の構文を検出

#### 使用方法

```bash
# 単一ファイルのチェック
shellcheck script.sh

# 全シェルスクリプトのチェック
find . -name "*.sh" -type f -print0 | xargs -0 shellcheck

# 警告レベルを指定
shellcheck --severity=warning script.sh
```

#### 重要な警告コード

- **SC2086**: 変数のクォート不足
- **SC2046**: コマンド置換のクォート不足
- **SC2004**: $((..)) の中での $ 使用
- **SC2181**: 直接 $? をチェック（|| や && を使うべき）
- **SC2164**: cd コマンドの失敗をチェックしていない

### shfmt

shfmt は、シェルスクリプトのフォーマットを統一するツールです。

#### フォーマット設定

このプロジェクトでは以下の設定を使用します:

```bash
shfmt -i 2 -ci -bn
```

- `-i 2`: インデントは2スペース
- `-ci`: switch文の中身をインデント
- `-bn`: バイナリ演算子（`&&`, `||` など）を改行前に配置

#### 使用方法

```bash
# フォーマットチェック（差分表示）
shfmt -i 2 -ci -bn -d script.sh

# フォーマット適用
shfmt -i 2 -ci -bn -w script.sh

# 全シェルスクリプトのフォーマットチェック
find . -name "*.sh" -type f -print0 | xargs -0 shfmt -i 2 -ci -bn -d

# 全シェルスクリプトのフォーマット適用
find . -name "*.sh" -type f -print0 | xargs -0 shfmt -i 2 -ci -bn -w
```

## 実行環境

### ローカル実行（Docker）

```bash
# Docker イメージのビルド
docker build -f Dockerfile.shell-linting -t shell-linting .

# Docker Compose で実行
docker-compose -f docker-compose.shell-linting.yml run shell-linting

# または、docker run で実行
docker run --rm -v $(pwd):/workspace shell-linting
```

### ローカル実行（直接インストール）

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y shellcheck

# shfmt のインストール
wget -O /usr/local/bin/shfmt https://github.com/mvdan/sh/releases/download/v3.8.0/shfmt_v3.8.0_linux_amd64
chmod +x /usr/local/bin/shfmt

# macOS (Homebrew)
brew install shellcheck shfmt
```

### CI/CD (GitHub Actions)

`.github/workflows/shell-linting.yml` で自動実行されます。

- Pull Request 時: `.sh` ファイルの変更時に自動実行
- Push 時: main ブランチへのプッシュ時に自動実行
- 手動実行: workflow_dispatch でいつでも実行可能

## ベストプラクティス

### 1. スクリプトヘッダー

すべてのシェルスクリプトには適切なシバンを含める:

```bash
#!/bin/bash
# または POSIX互換性が必要な場合
#!/bin/sh
```

### 2. set オプションの使用

エラー検出を強化するため、スクリプトの冒頭に以下を含める:

```bash
set -euo pipefail
```

- `-e`: コマンドがエラーで終了したら即座にスクリプトを終了
- `-u`: 未定義変数の使用時にエラー
- `-o pipefail`: パイプライン内のいずれかのコマンドが失敗したら全体を失敗とする

### 3. 変数のクォート

変数展開時は常にダブルクォートを使用:

```bash
# 悪い例
cd $directory
echo $variable

# 良い例
cd "$directory"
echo "$variable"
```

### 4. コマンドの成功/失敗チェック

重要なコマンドの結果は必ずチェック:

```bash
# 悪い例
cd /some/directory
rm -rf *

# 良い例
cd /some/directory || { echo "Failed to change directory"; exit 1; }
rm -rf ./*

# または
if ! cd /some/directory; then
  echo "Failed to change directory"
  exit 1
fi
```

### 5. 関数の使用

複雑なロジックは関数に分割:

```bash
main() {
  local arg1="$1"
  local arg2="$2"

  validate_args "$arg1" "$arg2"
  process_data "$arg1"
  cleanup
}

validate_args() {
  if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo "Error: Missing required arguments"
    return 1
  fi
}

# スクリプトの最後
main "$@"
```

## よくあるエラーと修正方法

### SC2086: 変数のクォート不足

```bash
# エラー
files=$( ls *.txt )
for file in $files; do
  echo $file
done

# 修正
while IFS= read -r file; do
  echo "$file"
done < <(find . -name "*.txt" -type f)
```

### SC2164: cd の失敗をチェックしていない

```bash
# エラー
cd "$directory"
rm -rf *

# 修正
cd "$directory" || exit 1
rm -rf ./*
```

### SC2181: $? の直接チェック

```bash
# エラー
some_command
if [ $? -eq 0 ]; then
  echo "Success"
fi

# 修正
if some_command; then
  echo "Success"
fi
```

## GitHub Copilot との統合

このスキルは `.claude/skills/` 配下に配置されていますが、Issue #21 の実装後は `.github/skills/` に移動され、GitHub Copilot からも参照可能になります。

## 参考リンク

- [shellcheck GitHub](https://github.com/koalaman/shellcheck)
- [shellcheck Wiki](https://www.shellcheck.net/wiki/)
- [shfmt GitHub](https://github.com/mvdan/sh)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
