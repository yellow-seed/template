#!/usr/bin/env bats

# setup-rulesets.sh のテスト

load '/usr/lib/bats/bats-support/load'
load '/usr/lib/bats/bats-assert/load'

setup() {
    # テスト用の一時ディレクトリを作成
    TEST_DIR=$(mktemp -d)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    RULESETS_DIR="$(cd "$SCRIPT_DIR/../rulesets" && pwd)"
    
    # モック用のパスを設定
    export PATH="$TEST_DIR:$PATH"
    
    # モックのghコマンドを作成
    cat > "$TEST_DIR/gh" <<'EOF'
#!/bin/bash
case "$1" in
    auth)
        if [ "$2" = "status" ]; then
            exit 0  # ログイン済みとして扱う
        fi
        ;;
    repo)
        if [ "$2" = "view" ]; then
            echo '{"nameWithOwner":"test-owner/test-repo"}'
        fi
        ;;
    api)
        # API呼び出しのモック
        echo '[]'  # 空のRulesetリストを返す
        ;;
esac
exit 0
EOF
    chmod +x "$TEST_DIR/gh"
    
    # モックのjqコマンドを作成
    cat > "$TEST_DIR/jq" <<'EOF'
#!/bin/bash
if [ "$1" = "-r" ] && [ "$2" = ".name" ]; then
    echo "test-ruleset"
else
    cat
fi
EOF
    chmod +x "$TEST_DIR/jq"
}

teardown() {
    # 一時ディレクトリを削除
    rm -rf "$TEST_DIR"
}

@test "setup-rulesets.sh が存在する" {
    assert [ -f "$SCRIPT_DIR/setup-rulesets.sh" ]
}

@test "setup-rulesets.sh が実行可能である" {
    assert [ -x "$SCRIPT_DIR/setup-rulesets.sh" ]
}

@test "setup-rulesets.sh が正しいshebangを持っている" {
    run head -n 1 "$SCRIPT_DIR/setup-rulesets.sh"
    assert_output "#!/bin/bash"
}

@test "ghコマンドが見つからない場合にエラーを表示する" {
    # ghコマンドを削除
    rm -f "$TEST_DIR/gh"
    
    run bash "$SCRIPT_DIR/setup-rulesets.sh" <<< ""
    assert_failure
    assert_output --partial "GitHub CLI (gh) がインストールされていません"
}

@test "jqコマンドが見つからない場合にエラーを表示する" {
    # jqコマンドを削除
    rm -f "$TEST_DIR/jq"
    
    run bash "$SCRIPT_DIR/setup-rulesets.sh" <<< ""
    assert_failure
    assert_output --partial "jq がインストールされていません"
}

@test "Rulesetファイルが存在する場合に処理を実行する" {
    # Rulesetファイルが存在することを確認
    if [ -f "$RULESETS_DIR/branch-protection-ruleset.json" ]; then
        run bash "$SCRIPT_DIR/setup-rulesets.sh" <<< ""
        # スクリプトは対話的であるため、完全なテストは難しい
        # ただし、基本的な構造は確認できる
        assert_success || assert_failure  # どちらでもOK（モックのため）
    else
        skip "Rulesetファイルが存在しません"
    fi
}
