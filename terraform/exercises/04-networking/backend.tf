# Partial backend config on purpose - see exercise 01's backend.tf for why.
#   terraform init \
#     -backend-config="resource_group_name=<from bootstrap output>" \
#     -backend-config="storage_account_name=<from bootstrap output>"
terraform {
  backend "azurerm" {
    container_name = "tfstate"
    key            = "04-networking.tfstate"
  }
}
