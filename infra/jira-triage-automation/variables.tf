variable "git_repo" {
  description = "Git repository the automation clones so the jira-triage skill is available."
  type        = string
  default     = "github.com/gsanuprasad/triage"
}

variable "git_branch" {
  description = "Branch containing the jira-triage skill."
  type        = string
  default     = "master"
}

variable "scope" {
  description = <<-EOT
    Automation ownership scope.
    Use "team_visible" so the team can view it while it still runs as your user
    (needed for Atlassian OAuth). Use "team" only if the team service account
    has Atlassian authenticated on the automation.
  EOT
  type        = string
  default     = "team_visible"
}
