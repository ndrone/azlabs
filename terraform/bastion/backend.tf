terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragellkwpibzju"
    container_name       = "tfstate-sc"
    key                  = "bastion.tfstate"
  }
}