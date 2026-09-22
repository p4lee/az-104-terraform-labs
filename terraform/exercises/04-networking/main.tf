module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "az-104-portfolio"
    domain  = "networking"
  }
}

module "vnet_workload" {
  source = "../../modules/virtual-network"

  name                = "vnet-az104-workload"
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = ["10.10.0.0/16"]
  subnets = {
    "snet-vms"  = ["10.10.1.0/24"]
    "snet-vmss" = ["10.10.2.0/24"]
  }

  tags = {
    project = "az-104-portfolio"
    domain  = "networking"
  }
}

# One NSG per subnet (nsg-vms, nsg-vmss) so each subnet's rules can evolve
# independently. No custom rules yet - those come later in this exercise.
module "nsg" {
  source   = "../../modules/network-security-group"
  for_each = module.vnet_workload.subnet_ids

  name                = "nsg-${trimprefix(each.key, "snet-")}"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = each.value
}

# Explicit outbound for both (private) subnets.
module "nat_gateway" {
  source = "../../modules/nat-gateway"

  name                = "nat-az104-workload"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_ids          = module.vnet_workload.subnet_ids

  tags = {
    project = "az-104-portfolio"
    domain  = "networking"
  }
}
