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

resource "github_repository_ruleset" "branch_protection" {
  name        = "Branch Protection Ruleset"
  repository  = github_repository.template.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = [
        "refs/heads/main",
        "refs/heads/develop",
        "refs/heads/release/*"
      ]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
    update           = true

    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
      require_code_owner_review       = false
      require_last_push_approval      = false
      required_review_thread_resolution = false
    }

    required_status_checks {
      strict_required_status_checks_policy = true

      required_check {
        context = "ci"
      }
    }
  }

  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }
}

resource "github_repository_ruleset" "feature_branch" {
  name        = "Feature Branch Ruleset"
  repository  = github_repository.template.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = [
        "refs/heads/feature/*",
        "refs/heads/feat/*"
      ]
      exclude = []
    }
  }

  rules {
    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
      require_code_owner_review       = false
      require_last_push_approval      = false
      required_review_thread_resolution = false
    }
  }

  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }
}
