## なぜやるか

GitHub Actionsのバージョンタグ参照（`@v6`など）はサプライチェーン攻撃のリスクがあり、`ubuntu-latest`はランナーバージョンの予期しない変更につながる。suzuki-shunsuke/pinactによるガードを導入し、アクションのSHA固定を強制するとともに、ランナーを`ubuntu-24.04`に固定してCIの再現性と安全性を高める。

## Ref

- [suzuki-shunsuke/pinact](https://github.com/suzuki-shunsuke/pinact) - GitHub ActionsのバージョンをSHAハッシュに固定するツール
- [GitHub Actions caching and runner versions](https://github.com/actions/runner-images) - ランナーイメージのライフサイクル
