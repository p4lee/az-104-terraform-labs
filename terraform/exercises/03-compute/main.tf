# Networking (VNet, subnets, NSGs, NAT gateway) lives in exercise 04 and its
# own resource group. This exercise only creates compute and reads the
# subnet IDs from 04's state file - so 04 must be applied first.
data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "04-networking.tfstate"
  }
}

locals {
  subnet_ids = data.terraform_remote_state.networking.outputs.subnet_ids
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "az-104-portfolio"
    domain  = "compute"
  }
}

module "vm" {
  source = "../../modules/linux-vm"
  count  = var.deploy_single_vm ? 1 : 0

  name                 = "vm-az104-compute"
  resource_group_name  = module.resource_group.name
  location             = var.location
  zone                 = var.vm_zone
  size                 = var.vm_size
  subnet_id            = local.subnet_ids["snet-vms"]
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key

  tags = {
    project = "az-104-portfolio"
    domain  = "compute"
  }
}

module "vmss" {
  source = "../../modules/linux-vmss"

  name                 = "vmss-az104-compute"
  resource_group_name  = module.resource_group.name
  location             = var.location
  size                 = var.vmss_size
  instance_count       = var.vmss_instance_count
  zones                = var.vmss_zones
  subnet_id            = local.subnet_ids["snet-vmss"]
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key

  tags = {
    project = "az-104-portfolio"
    domain  = "compute"
  }
}
