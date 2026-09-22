output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "Resource ID of the virtual network."
}

output "name" {
  value       = azurerm_virtual_network.this.name
  description = "Name of the virtual network."
}

output "subnet_ids" {
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
  description = "Map of subnet name to subnet resource ID."
}
