# Configure the Azure Provider
terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
    databricks = {
      source = "databricks/databricks"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.48.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "1.4.0"
    }
  }

  # Update this block with the location of your terraform state file
  backend "azurerm" {
    resource_group_name  = "terraform-sc-rg"
    storage_account_name = "tysdscinfratfsa"
    container_name       = "databricks"
    key                  = "devintus-stack"
    use_oidc             = true
###
/*
    access_key           = ""
    subscription_id      = ""
    client_id            = ""
    client_secret        = ""
    tenant_id            = ""
*/
  }
}


provider "azuread" {
  # Configuration options
}

provider "azurerm" {
  features {
    resource_group {
        prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = false
      #
      # not compatible with byok ADF keyvault setup, retrieval, and encryption...
      #
      #recover_soft_deleted_key_vaults = true
    }
  }
//  skip_credentials_validation
}


locals {
  tags = {
    BusinessUnit    = "Tyee Software Engineering"
    CostCenter      = "333-32555-000"
    Environment     = var.environment
    SXAPPID         = var.sxappid
    AppName         = var.name
    OwnerEmail      = var.owner_email
    Platform        = var.platform
    PlatformAppName = "${var.platform}-${var.name}"
  }
}

//
// IP addresses of ADO machines around the globe to let in...
//
locals {
  devops = [
          "20.37.158.0/23",
          "20.37.194.0/24",
          "20.39.13.0/26",
          "20.41.6.0/23",
          "20.41.194.0/24",
          "20.42.5.0/24",
          "20.42.134.0/23",
          "20.42.226.0/24",
          "20.45.196.64/26",
          "20.189.107.0/24",
          "20.195.68.0/24",
          "40.74.28.0/23",
          "40.80.187.0/24",
          "40.82.252.0/24",
          "40.119.10.0/24",
          "51.104.26.0/24",
          "52.150.138.0/24",
          "52.228.82.0/24",
          "191.235.226.0/24",
          "20.51.251.83",
          "20.98.103.209",
          "98.232.189.107",
          "20.37.194.0/24",
          "20.42.226.0/24",
          "191.235.226.0/24",
          "52.228.82.0/24",
          "20.37.158.0/23",
          "20.45.196.64/26",
          "20.189.107.0/24",
          "20.42.5.0/24",
          "20.41.6.0/23",
          "20.39.13.0/26",
          "40.80.187.0/24",
          "40.119.10.0/24",
          "20.41.194.0/24",
          "20.195.68.0/24",
          "51.104.26.0/24",
          "52.150.138.0/24",
          "40.74.28.0/23",
          "40.82.252.0/24",
          "20.42.134.0/23",
          //my local ip....this can not have a /32 it will fail and you will be left wondering why it failed...chasing your tail
          "76.138.138.227"
  ]
}

resource "azurerm_resource_group" "main" {
#  depends_on = [null_resource.delete_the_generated_files]

  name     = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}-rg"
  location = var.location

  tags = local.tags
}

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
  depends_on = [azurerm_resource_group.main]

  name                = local.nsg_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                   = "https"
    priority               = 100
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    source_address_prefix  = "*"
    destination_port_range = "443"
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
    name              = "everything_else_out"
    priority          = 210
    direction         = "Outbound"
    access            = "Deny"
    protocol          = "*"
    source_port_range = "*"
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
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_default]
#  network_security_group_id = azurerm_network_security_group.nsg.id
#  service_endpoints         = ["Microsoft.Storage"]
}
*/

resource "azurerm_subnet" "subnet_addressGatewaySubnet" {
  depends_on = [azurerm_virtual_network.vnet]

  name                      = "GatewaySubnet"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_gatewaySubnet]
}

resource "azurerm_subnet" "subnet_addressPrivateSQL" {
  depends_on = [azurerm_virtual_network.vnet]

  name                      = "PrivateSQL"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_privateSQL]
}

resource "azurerm_subnet" "subnet_addressPrivateStorage" {
  depends_on = [azurerm_virtual_network.vnet]

  name                      = "PrivateStorage"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_privateStorage]
}

resource "azurerm_subnet" "subnet_addressDataFactory" {
  depends_on = [azurerm_virtual_network.vnet]

  name                      = "DataFactory"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_dataFactory]
  service_endpoints         = ["Microsoft.Storage","Microsoft.KeyVault"]
}

resource "azurerm_subnet" "subnet_addressDataBricksPrivate" {
  depends_on = [azurerm_virtual_network.vnet]

  name                      = "DataBricksPrivate"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_dataBricksPrivate]
  service_endpoints         = ["Microsoft.Storage"]

  delegation {
    name = "workspaces_delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
    }
  }
}

resource "azurerm_subnet" "subnet_addressDataBricksPublic" {
  depends_on = [azurerm_virtual_network.vnet]

  name                      = "DataBricksPublic"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  address_prefixes          = [var.subnet_address_dataBricksPublic]
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
  depends_on = [azurerm_resource_group.main]

  name                = local.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_address_space]

  tags = local.tags
}

locals {
  sa_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}"
  sa_base_name = lower(replace(local.sa_temp_name, "/[[:^alnum:]]/", ""))
  sa_name = "${substr(
    local.sa_base_name,
    0,
    length(local.sa_base_name) < 22 ? -1 : 22,
  )}sa"
}

resource "azurerm_storage_account" "databricks_sa" {
  depends_on = [azurerm_resource_group.main]

  name                      = local.sa_name
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  enable_https_traffic_only = "true"
  min_tls_version           = "TLS1_2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  is_hns_enabled            = "true"

 network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
  }

  tags = local.tags
}

#
# Go get the object_id for the group name...
#
data "azuread_group" "adgroup_adf_owner" {
  display_name     = var.aad_group_env_adf_folder_owner
  security_enabled = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "databricks_sa_data_lake_gen2" {
  depends_on = [data.azuread_group.adgroup_adf_owner]
  name               = "inbound"
  storage_account_id = azurerm_storage_account.databricks_sa.id
/*
  dynamic "ace" {
    for_each = var.the_scopes
    content {
        type = "group"
        scope = ace.value
        id = data.azuread_group.adgroup_adf_owner.object_id
        permissions = "rwx"
    }
  }

  owner = "$superuser"
  group = "$superuser"
*/
}

resource "azurerm_storage_account_network_rules" "databricks_sa_network_rules" {
  depends_on = [azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2]
  storage_account_id       = azurerm_storage_account.databricks_sa.id

  default_action             = "Deny"
  ip_rules                   = ["4.15.128.98","207.189.104.116","76.138.138.227"]
  virtual_network_subnet_ids = [azurerm_subnet.subnet_addressDataBricksPrivate.id,azurerm_subnet.subnet_addressDataFactory.id]
  bypass                     = ["Metrics","AzureServices"]
}

data "azurerm_storage_account_blob_container_sas" "databricks_sa_sas_inbound" {
  depends_on = [azurerm_storage_account_network_rules.databricks_sa_network_rules]

  connection_string = azurerm_storage_account.databricks_sa.primary_connection_string
  container_name    = azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2.name
  https_only        = true

  //
  // Good for 2 years...
  //
  start  = timestamp()
  expiry = timeadd(timestamp(), "17520h")

  permissions {
    read    = true
    add     = true
    create  = true
    write   = true
    delete  = true
    list    = true
  }

  cache_control       = "max-age=5"
  content_disposition = "inline"
  content_encoding    = "deflate"
  content_language    = "en-US"
  content_type        = "application/json"
}

############################################################################################################
# ACLs
#

#
# Baseball...
#
resource "azurerm_storage_data_lake_gen2_path" "acl_payer_Baseball_theFolders" {
  depends_on = [azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2]

  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2.name
  storage_account_id = azurerm_storage_account.databricks_sa.id
  for_each           = var.theSubDirectories
  path               = "Baseball/${each.key}"
  resource           = "directory"

  dynamic "ace" {
    for_each = var.the_scopes
    content {
        type = "group"
        scope = ace.value
        id = data.azuread_group.adgroup_adf_owner.object_id
        permissions = "rwx"
    }
  }
}

#
# Copy over some baseball statistical csv files for testing purposes...
#
locals {
  azcopy_of_baseball_data_to_raw = <<EOF
azcopy copy "${path.module}\data\baseball\*.*" "${azurerm_storage_account.databricks_sa.primary_blob_endpoint}/inbound/Baseball/Raw${data.azurerm_storage_account_blob_container_sas.databricks_sa_sas_inbound.sas}" --recursive
EOF

}

resource "null_resource" "copy_over_baseball_stats_files_to_raw" {
  depends_on = [azurerm_storage_data_lake_gen2_path.acl_payer_Baseball_theFolders]

  provisioner "local-exec" {
    command    = local.azcopy_of_baseball_data_to_raw
    on_failure = continue
  }
}


#
# Setup container folders for DirectMail...
#
resource "azurerm_storage_data_lake_gen2_path" "acl_payer_DirectMail_theFolders" {
  depends_on = [azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2]

  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2.name
  storage_account_id = azurerm_storage_account.databricks_sa.id
  for_each           = var.theSubDirectories
  path               = "DirectMail/${each.key}"
  resource           = "directory"

  dynamic "ace" {
    for_each = var.the_scopes
    content {
        type = "group"
        scope = ace.value
        id = data.azuread_group.adgroup_adf_owner.object_id
        permissions = "rwx"
    }
  }
}

#
# Setup container folders for HomeCredit...
#
resource "azurerm_storage_data_lake_gen2_path" "acl_payer_HomeCredit_theFolders" {
  depends_on = [azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2]

  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2.name
  storage_account_id = azurerm_storage_account.databricks_sa.id
  for_each           = var.theSubDirectories
  path               = "HomeCredit/${each.key}"
  resource           = "directory"

  dynamic "ace" {
    for_each = var.the_scopes
    content {
        type = "group"
        scope = ace.value
        id = data.azuread_group.adgroup_adf_owner.object_id
        permissions = "rwx"
    }
  }
}

#
# Setup container folders for Models...
#
resource "azurerm_storage_data_lake_gen2_path" "acl_payer_Models_theFolders" {
  depends_on = [azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2]

  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2.name
  storage_account_id = azurerm_storage_account.databricks_sa.id
  for_each           = var.theSubDirectories
  path               = "Models/${each.key}"
  resource           = "directory"

  dynamic "ace" {
    for_each = var.the_scopes
    content {
        type = "group"
        scope = ace.value
        id = data.azuread_group.adgroup_adf_owner.object_id
        permissions = "rwx"
    }
  }
}

#
# Setup container folders for PowerCurve...
#
resource "azurerm_storage_data_lake_gen2_path" "acl_payer_PowerCurve_theFolders" {
  depends_on = [azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2]

  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2.name
  storage_account_id = azurerm_storage_account.databricks_sa.id
  for_each           = var.theSubDirectories
  path               = "PowerCurve/${each.key}"
  resource           = "directory"

  dynamic "ace" {
    for_each = var.the_scopes
    content {
        type = "group"
        scope = ace.value
        id = data.azuread_group.adgroup_adf_owner.object_id
        permissions = "rwx"
    }
  }
}


#
# az keyvault secret show --name "vsts-pat-dev-azure-com-gfs2" --vault-name "gfs-nn-terraform-akv" --query value --output tsv
#
# yields the following:
#
#<the vsts pat string...all 53 characters>
#
#.....az command works from the command line but not from within TF.....using the tf object model below, works like a champ!
#
data "azurerm_key_vault" "data_terraform_akv" {
#  depends_on = [azurerm_storage_data_lake_gen2_path.acl_payer_PowerCurve_theFolders]

  name                = var.key_vault_name
  resource_group_name = var.key_vault_resourcegroup
}

data "azurerm_key_vault_secret" "vsts_pat_keyvault_secret" {
  depends_on = [data.azurerm_key_vault.data_terraform_akv]

  name         = "vsts-pat-dev-azure-com-azx-tyeesoftware"
  key_vault_id = data.azurerm_key_vault.data_terraform_akv.id
}

####
# BYOK key for ADF....
#
resource "random_string" "forKeyvault" {
  length           = 8
  special          = false
}

locals {
  kv_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.name}-${var.platform}-${random_string.forKeyvault.result}"
  kv_base_name = lower(replace(local.kv_temp_name, "/[[:^alnum:]]/", ""))
  kv_name = "${substr( local.kv_base_name, 0, length(local.kv_base_name) < 21 ? -1 : 21 )}"
}

resource "azurerm_user_assigned_identity" "uaidentity" {
  name                = "${local.kv_name}-id"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}


resource "azurerm_key_vault" "keyvault" {

  name                     = "${local.kv_name}-kv"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  tenant_id                = var.tenantid
  sku_name                 = "premium"
  purge_protection_enabled = true
  soft_delete_retention_days = 7
  
  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
#    ip_rules       = ["20.51.251.83","20.98.103.209","98.232.189.107","13.65.175.147"]
    ip_rules       = local.devops
    virtual_network_subnet_ids = [azurerm_subnet.subnet_addressDataFactory.id]
  }
}

resource "azurerm_key_vault_access_policy" "azure_cli_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id = var.tenantid
  object_id = var.objectid

  key_permissions = [
      "Create", "List", "Get", "Delete", "Purge", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy"
  ]
}

resource "azurerm_key_vault_access_policy" "azure_dmw_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id = var.tenantid
  object_id = var.operatorObjectid

  key_permissions = [
      "Create", "List", "Get", "Delete", "Purge", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy"
  ]
}

resource "azurerm_key_vault_access_policy" "azure_uaidentity_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id = var.tenantid
  object_id = azurerm_user_assigned_identity.uaidentity.principal_id

  key_permissions = [
      "Create", "List", "Get", "Delete", "Purge", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy"
  ]
}

resource "azurerm_key_vault_key" "keyvaultkey" {
  depends_on = [azurerm_key_vault_access_policy.azure_dmw_policy]

  name         = "${local.kv_name}-ke"
  key_vault_id = azurerm_key_vault.keyvault.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

###
locals {
  ws_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}-dw"
  ws_base_name = lower(replace(local.ws_temp_name, "/[[:^alnum:]]/", ""))
  ws_name = "${substr(
    local.ws_base_name,
    0,
    length(local.ws_base_name) < 22 ? -1 : 22,
  )}-ws"
}

resource "azurerm_databricks_workspace" "databricks_workspace" {
  count = var.enable_databricks_creation ? 1 : 0

#  depends_on = [data.azurerm_key_vault_secret.vsts_pat_keyvault_secret]

  name                                      = local.ws_name
  resource_group_name                       = azurerm_resource_group.main.name
  location                                  = azurerm_resource_group.main.location
  sku                                       = "premium"
  customer_managed_key_enabled              = true
  managed_resource_group_name               = "${local.ws_name}-DBW-managed-services"
  public_network_access_enabled             = true
  network_security_group_rules_required     = "NoAzureDatabricksRules"

  custom_parameters {
    no_public_ip = true
    virtual_network_id  = azurerm_virtual_network.vnet.id
    private_subnet_name = azurerm_subnet.subnet_addressDataBricksPrivate.name
    public_subnet_name  = azurerm_subnet.subnet_addressDataBricksPublic.name

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.nsg_addressDataBricksPublic.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.nsg_addressDataBricksPrivate.id
  }

  tags = local.tags
}

locals {
  df_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}-df"
  df_base_name = lower(replace(local.df_temp_name, "/[[:^alnum:]]/", ""))
  df_name = "${substr(
    local.df_base_name,
    0,
    length(local.df_base_name) < 22 ? -1 : 22,
  )}-df"
}

resource "azurerm_data_factory" "data_factoryv2" {
  depends_on = [azurerm_databricks_workspace.databricks_workspace]
  name                = local.df_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type              = "SystemAssigned"
  }
  #
  # Add this block of code only for the devint stack, not for qa, stage, or prod
  # 

//  vsts_configuration  {
//    account_name    = var.vsts_account_name
//    branch_name     = var.vsts_branch_name
//    project_name    = var.vsts_project_name
//    repository_name = var.vsts_repository_name
//    root_folder     = var.vsts_root_folder
//    tenant_id       = var.vsts_tenant_id
//  }

   dynamic "github_configuration" {
    for_each = var.devops_git_setup
    content {
      account_name    = var.repo_account_name
      branch_name     = var.repo_branch_name
      git_url         = var.repo_git_url
      repository_name = var.repo_repository_name
      root_folder     = var.repo_adf_root_folder
    }
  }

  tags = local.tags
}

resource "azurerm_data_factory_integration_runtime_azure_ssis" "data_factoryv2_integration_runtime" {
  name                = "${local.df_name}-int-runtime"
  data_factory_id     = azurerm_data_factory.data_factoryv2.id
  location            = azurerm_resource_group.main.location

  node_size           = "Standard_D8_v3"
  number_of_nodes     = 3
  max_parallel_executions_per_node = 3
  edition             = "Enterprise"
  license_type        = "LicenseIncluded"

  vnet_integration {
    vnet_id = azurerm_virtual_network.vnet.id
    subnet_name = azurerm_subnet.subnet_addressDataFactory.name
  }
}

resource "azurerm_role_assignment" "adf-data-contributor-role" {
  depends_on = [azurerm_data_factory.data_factoryv2]

  scope                = azurerm_storage_account.databricks_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = azurerm_user_assigned_identity.uaidentity.principal_id
}

resource "azurerm_role_assignment" "adf-data-reader-role" {
  depends_on = [azurerm_data_factory.data_factoryv2]

  scope                = azurerm_storage_account.databricks_sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id = azurerm_user_assigned_identity.uaidentity.principal_id
}

#######################################################################################
# auth.terraform 
locals {
  subscription_id           = var.subscriptionid
  resource_group            = azurerm_resource_group.main.name
  databricks_workspace_name = azurerm_databricks_workspace.databricks_workspace[0].name
  tenant_id                 = var.tenantid
  databricks_workspace_host = azurerm_databricks_workspace.databricks_workspace[0].workspace_url
  databricks_workspace_id   = azurerm_databricks_workspace.databricks_workspace[0].workspace_id
}

provider "azapi" {
  subscription_id = var.subscriptionid
}

//
// This should have worked but didn't...needed to embed the ARM template below for this...
/*
resource "azapi_resource" "access_connector" {
  type      = "Microsoft.Databricks/accessConnectors@2022-10-01-preview"
  name      = "${local.ws_name}-databricks-mi"
  location  = azurerm_resource_group.main.location
  parent_id = azurerm_resource_group.main.id
  identity { 
            type = "UserAssigned"
            identity_ids = [azurerm_user_assigned_identity.uaidentity.id] 
           }
  body = jsonencode({ properties = {} })
}
*/
resource "azurerm_resource_group_template_deployment" "template" {
  name                = "${local.ws_name}-arm-template"
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "connectorName" = {
      value = "${local.ws_name}-databricks-mi"
    }
    "accessConnectorRegion" = {
      value = "${azurerm_resource_group.main.location}"
    }
    "userAssignedManagedIdentiy" = {
      value = "${azurerm_user_assigned_identity.uaidentity.id}"
    }
  })
  template_content = <<TEMPLATE
{
 "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
 "contentVersion": "1.0.0.0",
 "parameters": {
     "connectorName": {
         "defaultValue": "[parameters('connectorName')]",
         "type": "String",
         "metadata": {
             "description": "The name of the Azure Databricks Access Connector to create."
         }
     },
     "accessConnectorRegion": {
         "defaultValue": "[resourceGroup().location]",
         "type": "String",
         "metadata": {
             "description": "Location for the access connector resource."
         }
     },
     "userAssignedManagedIdentiy": {
         "type": "String",
         "metadata": {
             "description": "The resource Id of the user assigned managed identity."
         }
     }
 },
 "variables": {
    "_connectorName": "[parameters('connectorName')]",
    "_accessConnectorRegion": "[parameters('accessConnectorRegion')]",
    "_userAssignedManagedIdentiy": "[parameters('userAssignedManagedIdentiy')]"
  },
 "resources": [
     {
         "type": "Microsoft.Databricks/accessConnectors",
         "apiVersion": "2022-10-01-preview",
         "name": "[variables('_connectorName')]",
         "location": "[variables('_accessConnectorRegion')]",
         "identity": {
             "type": "UserAssigned",
             "userAssignedIdentities": {
                 "[variables('_userAssignedManagedIdentiy')]": {}
             }
         }
      }
   ],
    "outputs": {
      "principalid": {
        "type": "string",
        "value": "[variables('_userAssignedManagedIdentiy')]"
      }
    }
}
TEMPLATE

}
/*
data "azurerm_user_assigned_identity" "example" {
  name                = azurerm_user_assigned_identity.uaidentity.name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "databricks-data-contributor-role" {
  count = var.enable_databricks_creation ? 1 : 0

  depends_on = [azurerm_databricks_workspace.databricks_workspace]

  scope                = azurerm_storage_account.databricks_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.example.principal_id
}
*/
