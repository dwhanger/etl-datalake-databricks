# Input variable definitions
#
variable "tags" {
  description = "Tags to set on the resource"
  type        = map(string)
  default     = {}
}

/*
variable "resgroup_main" {
  description = "The main resource group object"
  type	  = list(string)
  default     = []
}
*/

variable "resgroup_main_name" {
  description = "The main resource group name"
  default     = ""
}

variable "resgroup_main_location" {
  description = "The main resource group location"
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
  default     = ""
}

variable "region" {
  description = "The region site code "
  default     = ""
}

variable "environment" {
  description = "The environment code (e.g. devint, qa, stage, prod)"
  default     = "devint"
}

variable "platform" {
  description = "Platform for tagging"
  default     = ""
}

variable "vnet_address_space" {
  description = "VNET address space"
  default     = ""
}

variable "subnet_address_prefix_default" {
  description = "Subnet for the default tier"
  default     = ""
}

variable "subnet_address_prefix_gatewaySubnet" {
  description = "Subnet for the gatewaySubnet tier"
  default     = ""
}

variable "subnet_address_prefix_privateSQL" {
  description = "Subnet for the privateSQL tier"
  default     = ""
}

variable "subnet_address_prefix_privateStorage" {
  description = "Subnet for the privateStorage tier"
  default     = ""
}

variable "subnet_address_prefix_dataFactory" {
  description = "Subnet for the dataFactory tier"
  default     = ""
}

variable "subnet_address_prefix_dataBricksPrivate" {
  description = "Subnet for the dataBricksPrivate tier"
  default     = ""
}

variable "subnet_address_prefix_dataBricksPublic" {
  description = "Subnet for the dataBricksPublic tier"
  default     = ""
}



