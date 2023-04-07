variable "subscriptionid" {
  description = "Subscription id for the subscription..."
  default     = ""
}

variable "tenantid" {
  description = "Tenant id for the subscription..."
  default     = ""
}

variable "objectid" {
  description = "Object id for the tf service principal..."
  default     = ""
}

variable "operatorObjectid" {
  description = "Object id for the user operator running the tf script from command line...needed for provisioning the keyvault..."
  default     = ""
}

variable "clientid" {
  description = "Client id for the tf service principal..."
  default     = ""
}
variable "clientsecret" {
  description = "Client secret for the tf service principal..."
  default     = ""
}


variable "name" {
  description = "Name to be used as basis for all resources."
  default     = ""
}

variable "short_name" {
  description = "Short name to be used as basis for all resources."
  default     = ""
}

variable "location" {
  description = "Azure region."
  default     = "eastus"
}

variable "region" {
  description = "The region site code (e.g. mue1)"
  default     = "gfs"
}

variable "environment" {
  description = "The environment code (e.g. prod)"
  default     = "devint"
}

variable "sxappid" {
  description = "SXAPPID for tagging"
  default     = ""
}

variable "owner_email" {
  description = "Owner DL for tagging"
  default     = ""
}

variable "platform" {
  description = "Platform for tagging"
  default     = ""
}

variable "vnet_address_space" {
  description = "VNET address space"
  default     = ""
}

variable "subnet_address_default" {
  description = "Subnet for the default tier"
  default     = ""
}

variable "subnet_address_gatewaySubnet" {
  description = "Subnet for the gatewaySubnet tier"
  default     = ""
}

variable "subnet_address_privateSQL" {
  description = "Subnet for the privateSQL tier"
  default     = ""
}

variable "subnet_address_privateStorage" {
  description = "Subnet for the privateStorage tier"
  default     = ""
}

variable "subnet_address_dataFactory" {
  description = "Subnet for the dataFactory tier"
  default     = ""
}

variable "subnet_address_dataBricksPrivate" {
  description = "Subnet for the dataBricksPrivate tier"
  default     = ""
}

variable "subnet_address_dataBricksPublic" {
  description = "Subnet for the dataBricksPublic tier"
  default     = ""
}

variable "key_vault_name" {
  description = "the name of the keyvault where the secrets are stored"
  default     = ""
}

variable "key_vault_resourcegroup" {
  description = "the resource group for the keyvault...keyvault in order to be accessible via tf needs to be in same subscription"
  default     = ""
}

variable "devops_git_setup" {
  description = "setup for devops git or not"
  default     = [""]
  type        = set(string)
}

variable "repo_account_name" {
  description = "the account name"
  default     = ""
}

variable "repo_branch_name" {
  description = "the branch name"
  default     = ""
}

variable "repo_project_name" {
  description = "the project name"
  default     = ""
}

variable "repo_git_url" {
  description = "the git url"
  default     = ""
}

variable "repo_repository_name" {
  description = "the repo name"
  default     = ""
}

variable "repo_syn_root_folder" {
  description = "the root folder for synapse in the git repo"
  default     = "/syn"
}

variable "repo_adf_root_folder" {
  description = "the root folder for adf in the git repo"
  default     = "/adf"
}

variable "repo_tenant_id" {
  description = "the tenant id"
  default     = ""
}

variable "aad_group_env_adf_folder_owner" {
  description = "AD group name for the ADF folder"
  default     = ""
}

variable "the_scopes" {
  description = "set of scope names"
  default     = ["access","default"]
  type        = set(string)
}


variable "theSubDirectories" {
  description = "set of directory names"
  default     = ["Archived","Exported","Ingested","Published","Raw","Transformed"]
  type        = set(string)
}

variable "enable_databricks_creation" {
  description = "whether to create databricks or not....aids in debugging"
  default     = true
  type        = bool
}
