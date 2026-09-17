#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the Terraform-based Jira triage automation repo.
# Installs a pinned Terraform version (if needed) and initializes the Terraform module
# so provider plugins matching the lockfile are available for validate/plan.
set -euo pipefail

TERRAFORM_VERSION="1.9.8"
TF_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_MODULE_DIR="${REPO_ROOT}/infra/jira-triage-automation-overnight"

install_terraform() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  curl -fsSL "$TF_URL" -o "$tmpdir/terraform.zip"
  unzip -o "$tmpdir/terraform.zip" -d "$tmpdir" >/dev/null
  sudo install -m 0755 "$tmpdir/terraform" /usr/local/bin/terraform
  rm -rf "$tmpdir"
}

if command -v terraform >/dev/null 2>&1 && terraform version | grep -q "Terraform v${TERRAFORM_VERSION}"; then
  echo "Terraform v${TERRAFORM_VERSION} already installed."
else
  echo "Installing Terraform v${TERRAFORM_VERSION}..."
  install_terraform
fi

terraform version

echo "Initializing Terraform module at ${TF_MODULE_DIR}..."
cd "$TF_MODULE_DIR"
terraform init -input=false

echo "Validating Terraform configuration..."
terraform validate

echo "Bootstrap complete."
