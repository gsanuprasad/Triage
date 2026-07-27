terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cursor = {
      source  = "cursor/cursor"
      version = "~> 0.1"
    }
  }
}

provider "cursor" {
  # Set CURSOR_TOKEN (key_... or crsr_... API key, or a session token).
}

resource "cursor_platform_workflow" "jira_triage_overnight" {
  name       = "Jira Triage — SD Overnight"
  scope      = var.scope
  enabled    = true
  prompt     = file("${path.module}/prompt.md")
  git_repo   = var.git_repo
  git_branch = var.git_branch

  # Every 15 minutes from 22:00 through 06:45 Australia/Sydney, plus 07:00
  # so the window is 10 PM–7 AM inclusive.
  trigger = [
    {
      cron = {
        schedule = "CRON_TZ=Australia/Sydney */15 22-23 * * *"
      }
    },
    {
      cron = {
        schedule = "CRON_TZ=Australia/Sydney */15 0-6 * * *"
      }
    },
    {
      cron = {
        schedule = "CRON_TZ=Australia/Sydney 0 7 * * *"
      }
    }
  ]

  action = [
    {
      # Exact casing required — lowercase "atlassian" will not resolve.
      mcp = {
        server = "Atlassian"
      }
    }
  ]
}

output "automation_id" {
  description = "Cursor automation ID"
  value       = cursor_platform_workflow.jira_triage_overnight.id
}

output "automation_url" {
  description = "Dashboard URL for the automation"
  value       = "https://cursor.com/automations/${cursor_platform_workflow.jira_triage_overnight.id}"
}
