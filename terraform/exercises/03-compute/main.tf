module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "az-104-portfolio"
    domain  = "compute"
  }
}

module "network" {
  source = "../../modules/virtual-network"

  name                   = "vnet-compute"
  resource_group_name    = module.resource_group.name
  location               = var.location
  address_space          = ["10.10.0.0/16"]
  subnet_name            = "snet-vms"
  subnet_address_prefix  = ["10.10.1.0/24"]
}

module "nsg" {
  source = "../../modules/network-security-group"

  name                = "nsg-compute"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.network.subnet_id
}

module "vm" {
  source = "../../modules/linux-vm"

  name                 = "vm-az104-compute"
  resource_group_name  = module.resource_group.name
  location             = var.location
  zone                 = var.vm_zone
  size                 = var.vm_size
  subnet_id            = module.network.subnet_id
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key

  tags = {
    project = "az-104-portfolio"
    domain  = "compute"
  }
}
