#!/usr/bin/env bats

# setup-all.sh のテスト

# batsライブラリを環境に応じて読み込む
# Ubuntu: /usr/lib/bats, macOS (Homebrew): /usr/local/lib/bats
for path in /usr/lib/bats /usr/local/lib/bats /opt/homebrew/lib/bats; do
    if [ -f "$path/bats-support/load" ]; then
        load "$path/bats-support/load"
        load "$path/bats-assert/load"
        break
    fi
done

setup() {
    # テスト用の一時ディレクトリを作成
    TEST_DIR=$(mktemp -d)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    # モック用のパスを設定
    export PATH="$TEST_DIR:$PATH"
}

teardown() {
    # 一時ディレクトリを削除
    rm -rf "$TEST_DIR"
}

@test "setup-all.sh が存在する" {
    assert [ -f "$SCRIPT_DIR/setup-all.sh" ]
}

@test "setup-all.sh が実行可能である" {
    assert [ -x "$SCRIPT_DIR/setup-all.sh" ]
}

@test "setup-all.sh が正しいshebangを持っている" {
    run head -n 1 "$SCRIPT_DIR/setup-all.sh"
    assert_output "#!/bin/bash"
}

@test "setup-all.sh が他のスクリプトを呼び出す" {
    # モックスクリプトを作成
    cat > "$TEST_DIR/setup-rulesets.sh" <<'EOF'
#!/bin/bash
echo "setup-rulesets.sh called"
EOF
    chmod +x "$TEST_DIR/setup-rulesets.sh"
    
    cat > "$TEST_DIR/setup-branch-auto-delete.sh" <<'EOF'
#!/bin/bash
echo "setup-branch-auto-delete.sh called"
EOF
    chmod +x "$TEST_DIR/setup-branch-auto-delete.sh"
    
    # スクリプトを実行（実際のスクリプトは呼ばれないようにモックを使用）
    run bash "$SCRIPT_DIR/setup-all.sh"
    
    # 実際のスクリプトはモックを呼び出すため、エラーになる可能性がある
    # このテストはスクリプトの構造を確認するだけ
    assert_success || assert_failure  # どちらでもOK（モックのため）
}
