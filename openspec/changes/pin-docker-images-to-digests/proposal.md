# Why

Dockerイメージのタグ参照はサプライチェーン攻撃のリスクがある。タグが書き換えられると、意図しないイメージがpullされる可能性がある。sha256ダイジェストによるピン留めを行うことで、このリスクを排除する。

# What

- Dockerfileのベースイメージをubuntu:22.04からubuntu:24.04に更新
- 全Dockerイメージに@sha256:<digest>を付与
- CIで`dockerfile-pin check`を実行し、digestの存在を検証
- dockerfile-pinはaquaのローカルregistryでバージョン管理し、CIでチェックサム検証付きでインストールする
