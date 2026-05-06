# Repository settings Terraform

`github_repository` リソースで、リポジトリの基本設定を管理します。

## 管理対象

- `description = "Template for AI era Develop"`
- `visibility = "public"`
- `is_template = true`
- `has_issues = true`
- `has_projects = true`
- `has_wiki = true`
- `has_discussions = false`
- `allow_merge_commit = true`
- `allow_squash_merge = true`
- `allow_rebase_merge = true`
- `allow_auto_merge = false`
- `delete_branch_on_merge = true`
- `allow_update_branch = false`
- squash / merge commit message 設定
- `web_commit_signoff_required = false`
- `vulnerability_alerts = true`

`security_and_analysis`、Actions 権限、Environment、Actions secrets の存在確認は
`.github/scripts/setup-repository-settings.sh` で管理します。

## 使い方

```bash
cd .github/terraform/repository-settings
terraform init
```

環境変数を設定してください。

```bash
export TF_VAR_github_owner="yellow-seed"
export TF_VAR_repository_name="template"
export TF_VAR_github_token="<PAT>"
```

既存リポジトリを import します。

```bash
terraform import github_repository.template template
```

差分確認:

```bash
terraform plan
```

## 補足

- `.github/scripts/setup-repository-settings.sh` は、GitHub UI で確認した実設定を
  GitHub API 経由で再適用するためのスクリプトです。
- Actions secrets の値はリポジトリへ保存しません。スクリプトは必要な secret 名の
  存在だけを確認します。
