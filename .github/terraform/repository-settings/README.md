# Repository settings Terraform

`github_repository` と `github_repository_ruleset` リソースで、
リポジトリの基本設定と Ruleset を管理します。

## 管理対象

- `delete_branch_on_merge = true`
- `allow_update_branch = true`
- `Branch Protection Ruleset`
  - `refs/heads/main`
  - `refs/heads/develop`
  - `refs/heads/release/*`
- `Feature Branch Ruleset`
  - `refs/heads/feature/*`
  - `refs/heads/feat/*`

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

既存設定を import します。

```bash
terraform import github_repository.template template
terraform import github_repository_ruleset.branch_protection <branch-protection-ruleset-id>
terraform import github_repository_ruleset.feature_branch <feature-branch-ruleset-id>
```

Ruleset ID の確認:

```bash
gh api repos/OWNER/REPO/rulesets --jq '.[] | {id: .id, name: .name}'
```

差分確認:

```bash
terraform plan
```

適用:

```bash
terraform apply
```

## 補足

- 旧スクリプト `.github/scripts/setup-branch-auto-delete.sh` と
  `.github/scripts/setup-branch-update-suggestion.sh` は、Terraform 移行後に削除予定です。
- 旧 Ruleset JSON と `setup-rulesets.sh` は互換目的で残しています。
- `terraform plan` がゼロ差分になることを確認してから不要な資産を整理してください。
