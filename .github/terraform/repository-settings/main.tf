terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

resource "github_repository" "template" {
  name = var.repository_name

  delete_branch_on_merge = true
  allow_update_branch    = true
}
