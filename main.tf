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
      source  = "hashicorp/azuread"
      version = "1.4.0"
    }
  }

  backend "azurerm" {}
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

data "azurerm_client_config" "current" {}

locals {
  tenant_id       = data.azurerm_client_config.current.tenant_id
  subscription_id = data.azurerm_client_config.current.subscription_id
  object_id       = data.azurerm_client_config.current.object_id
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
    "76.138.138.227"
  ]
}

//
// IP addresses of Github Actions machines around the globe to let in...
//
//
data "local_file" "githubactions_ipaddresses" {
  filename = "${path.module}/githubactions_ipaddresses.txt"
}
locals {
  githubactions_ipaddresses = split(",", trimspace(data.local_file.githubactions_ipaddresses.content))
}

resource "azurerm_resource_group" "main" {

  name     = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}-rg"
  location = var.location

  tags = local.tags
}

#
# Load up our module where we have the vnet, nsgs, and subnets defined...
#
module "azure_vnet_nsg_subnet" {
  source = "./modules/azure-vnet-nsg-subnet"

  resgroup_main_location                  = azurerm_resource_group.main.location
  resgroup_main_name                      = azurerm_resource_group.main.name
  name                                    = var.name
  short_name                              = var.short_name
  location                                = var.location
  platform                                = var.platform
  region                                  = var.region
  environment                             = var.environment
  vnet_address_space                      = var.vnet_address_space
  subnet_address_prefix_default           = var.subnet_address_default
  subnet_address_prefix_gatewaySubnet     = var.subnet_address_gatewaySubnet
  subnet_address_prefix_privateSQL        = var.subnet_address_privateSQL
  subnet_address_prefix_privateStorage    = var.subnet_address_privateStorage
  subnet_address_prefix_dataFactory       = var.subnet_address_dataFactory
  subnet_address_prefix_dataBricksPrivate = var.subnet_address_dataBricksPrivate
  subnet_address_prefix_dataBricksPublic  = var.subnet_address_dataBricksPublic
  tags                                    = local.tags
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
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = local.tags
}

#
# Go get the object_id for the group name...
#.....need a P2 license for the following to work because the group needs to be able to have roles assignable to it, eg: Group.Read.All
#
#data "azuread_group" "adgroup_adf_owner" {
#  display_name     = var.aad_group_env_adf_folder_owner
#  security_enabled = true
#}


resource "azurerm_storage_data_lake_gen2_filesystem" "databricks_sa_data_lake_gen2" {
  name               = "inbound"
  storage_account_id = azurerm_storage_account.databricks_sa.id
  /*
  dynamic "ace" {
    for_each = var.the_scopes
    content {
        type = "group"
        scope = ace.value
        #id = data.azuread_group.adgroup_adf_owner.object_id
        id          = var.adfObjectid
        permissions = "rwx"
    }
  }

  owner = "$superuser"
  group = "$superuser"
*/
}


resource "azurerm_storage_account_network_rules" "databricks_sa_network_rules" {
  depends_on         = [azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2]
  storage_account_id = azurerm_storage_account.databricks_sa.id

  default_action             = "Deny"
  ip_rules                   = ["4.15.128.98", "207.189.104.116", "76.138.138.227"]
  virtual_network_subnet_ids = [module.azure_vnet_nsg_subnet.subnet_address_prefix_dataBricksPrivate.id, module.azure_vnet_nsg_subnet.subnet_address_prefix_dataFactory.id]
  bypass                     = ["Metrics", "AzureServices"]
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
    read   = true
    add    = true
    create = true
    write  = true
    delete = true
    list   = true
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

  storage_account_id = azurerm_storage_account.databricks_sa.id
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.databricks_sa_data_lake_gen2.name
  for_each           = var.theSubDirectories
  path               = "Baseball/${each.key}"
  resource           = "directory"

  dynamic "ace" {
    for_each = var.the_scopes
    
    content {
      type  = "group"
      scope = ace.value
      #        id = data.azuread_group.adgroup_adf_owner.object_id
      id          = var.adfObjectid
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
      type  = "group"
      scope = ace.value
      #        id = data.azuread_group.adgroup_adf_owner.object_id
      id          = var.adfObjectid
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
      type  = "group"
      scope = ace.value
      #        id = data.azuread_group.adgroup_adf_owner.object_id
      id          = var.adfObjectid
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
      type  = "group"
      scope = ace.value
      #        id = data.azuread_group.adgroup_adf_owner.object_id
      id          = var.adfObjectid
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
      type  = "group"
      scope = ace.value
      #        id = data.azuread_group.adgroup_adf_owner.object_id
      id          = var.adfObjectid
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
/*
data "azurerm_key_vault" "data_terraform_akv" {

  name                = var.key_vault_name
  resource_group_name = var.key_vault_resourcegroup
}

data "azurerm_key_vault_secret" "vsts_pat_keyvault_secret" {
  depends_on = [data.azurerm_key_vault.data_terraform_akv]

  name         = "vsts-pat-dev-azure-com-azx-tyeesoftware"
  key_vault_id = data.azurerm_key_vault.data_terraform_akv.id
}
*/

####
# BYOK key for ADF....
#
resource "random_string" "forKeyvault" {
  length  = 8
  special = false
}

locals {
  kv_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.name}-${var.platform}-${random_string.forKeyvault.result}"
  kv_base_name = lower(replace(local.kv_temp_name, "/[[:^alnum:]]/", ""))
  kv_name      = substr(local.kv_base_name, 0, length(local.kv_base_name) < 21 ? -1 : 21)
}

resource "azurerm_user_assigned_identity" "uaidentity" {
  name                = "${local.kv_name}-id"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_key_vault" "keyvault" {

  name                       = "${local.kv_name}-kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = local.tenant_id
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = local.tenant_id
    object_id = local.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Set",
    ]
  }

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    #    ip_rules       = ["20.51.251.83","20.98.103.209","98.232.189.107","13.65.175.147"]
    #    ip_rules       = local.devops
    ip_rules                   = local.githubactions_ipaddresses
    virtual_network_subnet_ids = [module.azure_vnet_nsg_subnet.subnet_address_prefix_dataFactory.id]
  }
}
/*
resource "azurerm_key_vault_access_policy" "azure_cli_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id = local.tenant_id
  object_id = local.object_id

  key_permissions = [
      "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy", "Rotate", "Release", "Update", "Verify", "Decrypt", "Encrypt", "Sign"
  ]

  secret_permissions = [
      "List", "Get", "Delete", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
      "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore"
  ]

}
*/

resource "azurerm_key_vault_access_policy" "azure_dmw_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = local.tenant_id
  object_id    = var.operatorDMWObjectid

  key_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy", "Rotate", "Release", "Update", "Verify", "Decrypt", "Encrypt", "Sign"
  ]

  secret_permissions = [
    "List", "Get", "Delete", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore"
  ]

}


resource "azurerm_key_vault_access_policy" "azure_uaidentity_policy" {

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = local.tenant_id
  object_id    = azurerm_user_assigned_identity.uaidentity.principal_id

  key_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore", "UnwrapKey", "WrapKey", "GetRotationPolicy", "SetRotationPolicy", "Rotate", "Release", "Update", "Verify", "Decrypt", "Encrypt", "Sign"
  ]

  secret_permissions = [
    "List", "Get", "Delete", "Recover", "Restore", "Set"
  ]

  certificate_permissions = [
    "Create", "List", "Get", "Delete", "Purge", "Recover", "Restore"
  ]

}

resource "azurerm_key_vault_key" "keyvaultkey" {

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

  name                                  = local.ws_name
  resource_group_name                   = azurerm_resource_group.main.name
  location                              = azurerm_resource_group.main.location
  sku                                   = "premium"
  customer_managed_key_enabled          = true
  managed_resource_group_name           = "${local.ws_name}-DBW-managed-services"
  public_network_access_enabled         = true
  network_security_group_rules_required = "NoAzureDatabricksRules"

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = module.azure_vnet_nsg_subnet.vnet.id
    private_subnet_name = module.azure_vnet_nsg_subnet.subnet_address_prefix_dataBricksPrivate.name 
    public_subnet_name  = module.azure_vnet_nsg_subnet.subnet_address_prefix_dataBricksPublic.name

    public_subnet_network_security_group_association_id  = module.azure_vnet_nsg_subnet.nsg_addressDataBricksPublic.id
    private_subnet_network_security_group_association_id = module.azure_vnet_nsg_subnet.nsg_addressDataBricksPrivate.id
  }

  tags = local.tags
}


resource "azurerm_databricks_workspace_customer_managed_key" "databrickscmkey" {
  depends_on = [azurerm_key_vault_key.cmkey]

  workspace_id     = azurerm_databricks_workspace.databricks_workspace[0].id
  key_vault_key_id = azurerm_key_vault_key.cmkey.id
}

resource "azurerm_key_vault_key" "cmkey" {

  name         = "databrickscmkey-certificate"
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
}

resource "azurerm_key_vault_access_policy" "databricks" {
  depends_on = [azurerm_databricks_workspace.databricks_workspace]

  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = azurerm_databricks_workspace.databricks_workspace[0].storage_account_identity.0.tenant_id
  object_id    = azurerm_databricks_workspace.databricks_workspace[0].storage_account_identity.0.principal_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign"
  ]
}

locals {
  df_temp_name = "${var.short_name}${var.environment}-${var.region}-${var.platform}-${var.name}"
  df_base_name = lower(replace(local.df_temp_name, "/[[:^alnum:]]/", ""))
  df_name = "${substr(
    local.df_base_name,
    0,
    length(local.df_base_name) < 22 ? -1 : 22,
  )}-df"
}

resource "azurerm_data_factory" "data_factoryv2" {
  depends_on          = [azurerm_databricks_workspace.databricks_workspace]
  name                = local.df_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }
  #
  # Add this block of code only for the devint stack, not for qa, stage, or prod
  # 
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
  name            = "${local.df_name}-int-runtime"
  data_factory_id = azurerm_data_factory.data_factoryv2.id
  location        = azurerm_resource_group.main.location

  node_size                        = "Standard_D8_v3"
  number_of_nodes                  = 3
  max_parallel_executions_per_node = 3
  edition                          = "Enterprise"
  license_type                     = "LicenseIncluded"

  vnet_integration {
    vnet_id     = module.azure_vnet_nsg_subnet.vnet.id
    subnet_name = module.azure_vnet_nsg_subnet.subnet_address_prefix_dataFactory.name
  }
}

#######################################################################################
# auth.terraform 
locals {
  resource_group            = azurerm_resource_group.main.name
  databricks_workspace_name = azurerm_databricks_workspace.databricks_workspace[0].name
  databricks_workspace_host = azurerm_databricks_workspace.databricks_workspace[0].workspace_url
  databricks_workspace_id   = azurerm_databricks_workspace.databricks_workspace[0].workspace_id
}
/*
//
// This should have worked but didn't...needed to embed the ARM template below for this...
provider "azapi" {
  subscription_id = var.subscriptionid
}

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
