## 1. Dockerイメージのdigestピン留め

- [x] 1.1 Dockerfileのベースイメージをubuntu:22.04からubuntu:24.04に変更
- [x] 1.2 dockerfile-pinでDockerfileに@sha256:<digest>を付与
- [x] 1.3 dockerfile-pinでcompose.ymlに@sha256:<digest>を付与

## 2. CIでのdigest検証

- [x] 2.1 `.github/workflows/`に`dockerfile-pin check`を実行するworkflowを追加
- [x] 2.2 workflowはPR時に実行され、全イメージがdigestでピン留めされていることを検証
- [x] 2.3 dockerfile-pinはaquaでインストールし、ツールのバージョン更新に追随しやすくする

## 3. 後片付け

- [x] 3.1 mainブランチのworktreeで/tmp/dockerfile-pinを削除（存在する場合）
