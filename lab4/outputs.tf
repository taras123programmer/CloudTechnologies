output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "shared_services_subnet_id" {
  value = azurerm_subnet.shared.id
}

output "database_subnet_id" {
  value = azurerm_subnet.db.id
}

output "asg_web_id" {
  description = "ID створеної Application Security Group"
  value       = azurerm_application_security_group.asg_web.id
}
