# Partial backend config on purpose: the account-specific values
# (resource_group_name, storage_account_name) are supplied at `terraform init`
# time via -backend-config, so nothing account-specific is committed to git.
#
#   terraform init \
#     -backend-config="resource_group_name=<from bootstrap output>" \
#     -backend-config="storage_account_name=<from bootstrap output>"
terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key             = "01-governance.tfstate"
  }
}
