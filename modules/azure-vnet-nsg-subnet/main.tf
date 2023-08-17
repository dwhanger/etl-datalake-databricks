
locals {
  nsg_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}"
  nsg_base_name = lower(replace(local.nsg_temp_name, "/[[:^alnum:]]/", ""))
  nsg_name = "${substr(
    local.nsg_base_name,
    0,
    length(local.nsg_base_name) < 21 ? -1 : 21,
  )}-nsg"
}

resource "azurerm_network_security_group" "nsg" {
  
  name                = local.nsg_name
  location            = var.resgroup_main_location
  resource_group_name = var.resgroup_main_name

  security_rule {
    name                       = "https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name              = "http_Out"
    priority          = 120
    direction         = "Outbound"
    access            = "Allow"
    protocol          = "Tcp"
    source_port_range = "*"

    source_address_prefix      = "*"
    destination_port_range     = "80"
    destination_address_prefix = "*"
  }
  security_rule {
    name              = "https_Out"
    priority          = 130
    direction         = "Outbound"
    access            = "Allow"
    protocol          = "Tcp"
    source_port_range = "*"

    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = "*"
  }
  security_rule {
    name                   = "everything_else_in"
    priority               = 200
    direction              = "Inbound"
    access                 = "Deny"
    protocol               = "*"
    source_port_range      = "*"
    source_address_prefix  = "*"
    destination_port_range = "*"

    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "everything_else_out"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    destination_address_prefix = "*"
  }
}


locals {
  vnet_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}"
  vnet_base_name = lower(replace(local.vnet_temp_name, "/[[:^alnum:]]/", ""))
  vnet_name = "${substr(
    local.vnet_base_name,
    0,
    length(local.vnet_base_name) < 20 ? -1 : 20,
  )}-vnet"
}

/*
resource "azurerm_subnet" "subnet_addressDefault" {
  depends_on = [azurerm_virtual_network.vnet]

  name                      = "default"
  resource_group_name       = var.resgroup_main_name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_prefix_default]
#  network_security_group_id = azurerm_network_security_group.nsg.id
#  service_endpoints         = ["Microsoft.Storage"]
}
*/

resource "azurerm_subnet" "subnet_addressGatewaySubnet" {
  depends_on = [azurerm_virtual_network.vnet]

  name                 = "GatewaySubnet"
  resource_group_name  = var.resgroup_main_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix_gatewaySubnet]
}

resource "azurerm_subnet" "subnet_addressPrivateSQL" {
  depends_on = [azurerm_virtual_network.vnet]

  name                 = "PrivateSQL"
  resource_group_name  = var.resgroup_main_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix_privateSQL]
}

resource "azurerm_subnet" "subnet_addressPrivateStorage" {
  depends_on = [azurerm_virtual_network.vnet]

  name                 = "PrivateStorage"
  resource_group_name  = var.resgroup_main_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix_privateStorage]
}

resource "azurerm_subnet" "subnet_addressDataFactory" {
  depends_on = [azurerm_virtual_network.vnet]

  name                 = "DataFactory"
  resource_group_name  = var.resgroup_main_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix_dataFactory]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "subnet_addressDataBricksPrivate" {
  depends_on = [azurerm_virtual_network.vnet]

  name                 = "DataBricksPrivate"
  resource_group_name  = var.resgroup_main_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix_dataBricksPrivate]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "workspaces_delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "subnet_addressDataBricksPublic" {
  depends_on = [azurerm_virtual_network.vnet]

  name                 = "DataBricksPublic"
  resource_group_name  = var.resgroup_main_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefix_dataBricksPublic]
  delegation {
    name = "workspaces_delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "nsg_addressDataBricksPrivate" {
  subnet_id                 = azurerm_subnet.subnet_addressDataBricksPrivate.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_addressDataBricksPublic" {
  subnet_id                 = azurerm_subnet.subnet_addressDataBricksPublic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_network" "vnet" {
#  depends_on = [var.resgroup_main_name]

  name                = local.vnet_name
  location            = var.resgroup_main_location
  resource_group_name  = var.resgroup_main_name
  address_space       = [var.vnet_address_space]

  tags = var.tags
}


