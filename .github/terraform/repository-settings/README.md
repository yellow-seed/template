# Repository settings Terraform

`github_repository` リソースで、リポジトリの基本設定を管理します。

## 管理対象

- `delete_branch_on_merge = true`
- `allow_update_branch = true`

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

- 旧スクリプト `.github/scripts/setup-branch-auto-delete.sh` と
  `.github/scripts/setup-branch-update-suggestion.sh` は、Terraform 移行後に削除予定です。
- `terraform plan` がゼロ差分になることを確認してから削除してください。
