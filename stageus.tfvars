azcliObjectid                    = "ae9480f8-724b-4719-81ff-6b9097b65d9e"
operatorDMWObjectid              = "<operatorDMWObjectid for stage>"
adfObjectid                      = "72860e6a-d7a8-428f-a0a9-c0e68c79bde8"
location                         = "southcentralus"
name                             = "databricks"
short_name                       = "data"
region                           = "sc"
environment                      = "s"
sxappid                          = "10046"
owner_email                      = "dwhanger@microsoft.com"
platform                         = "d8"
vnet_address_space               = "10.35.100.0/22"
subnet_address_default           = "172.18.3.0/24"
subnet_address_gatewaySubnet     = "10.35.100.0/26"
subnet_address_privateSQL        = "10.35.100.64/26"
subnet_address_privateStorage    = "10.35.100.128/26"
subnet_address_dataFactory       = "10.35.100.192/26"
subnet_address_dataBricksPrivate = "10.35.102.0/24"
subnet_address_dataBricksPublic  = "10.35.101.0/24"
key_vault_name                   = "tyss-sc-infra-tf-akv"
key_vault_resourcegroup          = "terraform-sc-rg"
repo_account_name                = "dwhanger"
repo_branch_name                 = "main"
repo_git_url                     = "https://github.com"
repo_repository_name             = "etl-datalake-databricks"
repo_adf_root_folder             = "/adf"
repo_syn_root_folder             = "/databricks"
repo_tenant_id                   = "4beecb38-fbf2-4aa5-aa0a-4aec609a959a"
aad_group_env_adf_folder_owner   = "Stage-ADF-Owner"
//devops_git_setup = ["stage"]         //unset this variable so there is nothing in the set to loop through and process
enable_databricks_creation = true
