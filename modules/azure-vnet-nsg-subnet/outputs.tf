# Output variable definitions

output "vnet" { 
  description = "VNET default Object"
  value       = azurerm_virtual_network.vnet
  
}

output "nsg_addressDataBricksPublic" { 
  description = "NSG databrics public Object"
  value       = azurerm_subnet_network_security_group_association.nsg_addressDataBricksPublic
}

output "nsg_addressDataBricksPrivate" { 
  description = "NSG databricks private Object"
  value       = azurerm_subnet_network_security_group_association.nsg_addressDataBricksPrivate
}

#output "subnet_address_prefix_default" { 
#  description = "Subnet default object"
#  value       = azurerm_subnet.subnet_addressDefault
#}

output "subnet_address_prefix_gatewaySubnet" {
  description = "Subnet gatewaySubnet object"
  value       = azurerm_subnet.subnet_addressGatewaySubnet
}

output "subnet_address_prefix_privateSQL" {
  description = "Subnet privatesql object"
  value       = azurerm_subnet.subnet_addressPrivateSQL
}

output "subnet_address_prefix_privateStorage" {
  description = "Subnet privateStorage object"
  value       = azurerm_subnet.subnet_addressPrivateStorage
}

output "subnet_address_prefix_dataFactory" {
  description = "Subnet dataFactory object"
  value       = azurerm_subnet.subnet_addressDataFactory
}

output "subnet_address_prefix_dataBricksPrivate" {
  description = "Subnet dataBricksPrivate object"
  value       = azurerm_subnet.subnet_addressDataBricksPrivate
}

output "subnet_address_prefix_dataBricksPublic" {
  description = "Subnet dataBricksPublic object"
  value       = azurerm_subnet.subnet_addressDataBricksPublic
}

