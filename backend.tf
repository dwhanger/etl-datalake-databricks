terraform {
  backend "azurerm" {
#devintus
    key                   = "devintus-stack"
    container_name        = "databricks"
    storage_account_name  = "tysdscinfratfsa"
    access_key            = "z05NUiT6goa2mIrSUrs7u9iIe9KE+D4sDvxIjPhhOHrrfpFKyDRU1T7g1XDwlv1x8fXL7ChIlOOA+AStOgdFhg=="
#qaus
#    key                   = "qaus-stack"
#
#   >> To list all Env variables:
#   >>  Get-ChildItem Env:
#   >>
#
#devintus
#qa
    resource_group_name   = "terraform-sc-rg"
    subscription_id       = "dfd44adf-0b1d-4309-b742-988a91722fe7"
    client_id             = "fe5a7e5d-c3e9-49a7-a9cf-aef07d968c30"
    client_secret         = "sHw8Q~qDrutv_7ZT.~BxNoSauALTk~e4WLJd0boK"
    tenant_id             = "4beecb38-fbf2-4aa5-aa0a-4aec609a959a"
  }
}



#
# set the TF_VARS_access_key environment variable to set the access key...don't put it here...
# powershell commands:
#   >> Set-Location Env:
#   >> $Env:TF_VARS_access_key="<the key for the storage account>"
#   >> Get-Content -Path TF_VARS_access_key
#
#   >> To list all Env variables:
#   >>  Get-ChildItem Env:
#   >>
