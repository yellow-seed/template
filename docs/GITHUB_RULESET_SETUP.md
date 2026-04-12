# GitHub Ruleset とブランチ保護設定ガイド

このドキュメントでは、GitHub Ruleset と関連するリポジトリ設定を
Terraform で管理する方法を説明します。
このテンプレートを取り込んだ他リポジトリでは不要だと思われます。
必要に応じて削除してください。

## 概要

GitHub の以下設定を Terraform でコード管理できます。

- Branch Protection Ruleset（`main` / `develop` / `release/*`）
- Feature Branch Ruleset（`feature/*` / `feat/*`）
- `delete_branch_on_merge`
- `allow_update_branch`

## 前提条件

- Terraform がインストールされていること
- GitHub リポジトリへの管理者権限があること
- リポジトリ設定変更可能な GitHub Personal Access Token を持っていること

## セットアップ方法

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

## 既存設定の import

既存の設定を Terraform 管理へ移行する場合は、先に import してください。

```bash
terraform import github_repository.template template
terraform import github_repository_ruleset.branch_protection <branch-protection-ruleset-id>
terraform import github_repository_ruleset.feature_branch <feature-branch-ruleset-id>
```

Ruleset ID は GitHub CLI で確認できます。

```bash
gh api repos/OWNER/REPO/rulesets --jq '.[] | {id: .id, name: .name}'
```

## 差分確認と適用

```bash
terraform plan
terraform apply
```

移行後は `terraform plan` でゼロ差分になることを確認してください。

## 管理中の Ruleset 内容

### Branch Protection Ruleset

- 対象: `refs/heads/main`, `refs/heads/develop`, `refs/heads/release/*`
- Pull Request 必須
- 承認 1 名以上
- stale review dismiss 有効
- status check `ci` 必須（strict）
- non-fast-forward / deletion / update 制御
- `RepositoryRole`（actor_id: 5）の bypass 設定あり

### Feature Branch Ruleset

- 対象: `refs/heads/feature/*`, `refs/heads/feat/*`
- Pull Request 必須
- 承認 1 名以上
- stale review dismiss 有効
- `RepositoryRole`（actor_id: 5）の bypass 設定あり

## 補足

旧 Ruleset JSON と `setup-rulesets.sh` は互換目的で残してあります。
実運用では Terraform 側を正としてください。

## 参考資料

- [Terraform GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [GitHub Rulesets API ドキュメント](https://docs.github.com/en/rest/repos/rules)
