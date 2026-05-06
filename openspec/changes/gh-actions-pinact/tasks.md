## 1. pinactの導入とアクションのSHA固定

- [x] 1.1 `mise.toml`にpinactを追加
- [x] 1.2 `.pinact.yml`をデフォルト設定で作成
- [x] 1.3 `pinact run`を実行し、全workflowファイルのアクションバージョンをSHAハッシュに書き換え

## 2. ランナーの固定

- [x] 2.1 全workflowファイルの`runs-on: ubuntu-latest`を`runs-on: ubuntu-24.04`に変更

## 3. バージョン統一

- [x] 3.1 `actions/checkout@v4`を使用しているworkflow（verify-codex-setup.yml, openspec-archive.yml）を`@v6`に統一（pinact run後にSHAが更新される）

## 4. Dependabot設定の更新

- [x] 4.1 `versioning-strategy: increase`を`widen`に変更（ Dependabotがバージョン範囲を更新し、pinactと共存できるようにする）

## 5. pinact CIジョブの追加

- [x] 5.1 ci.ymlにpinact検証ジョブを追加（`pinact verify`でSHA固定が維持されているかチェック）

## 6. 動作検証

- [x] 6.1 CIが全ジョブ通ることを確認
