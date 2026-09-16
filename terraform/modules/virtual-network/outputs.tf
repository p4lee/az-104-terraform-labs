output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "Resource ID of the virtual network."
}

output "subnet_id" {
  value       = azurerm_subnet.this.id
  description = "Resource ID of the subnet."
}
