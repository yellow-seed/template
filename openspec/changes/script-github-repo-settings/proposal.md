## なぜやるか

GitHub リポジトリの UI 側で変更された設定が、現在の `.github/scripts/` や Terraform の管理対象に含まれていない。テンプレートリポジトリとして再現性を保つため、GitHub API で取得でき、かつ値を安全にコード化できる repository / Actions / security / environment 設定をスクリプトへ反映する。

## Ref

- ユーザー依頼: GitHub UI 側で変更した設定を確認し、スクリプト化できるものをすべて反映
- GitHub 実設定確認日: 2026-05-06
