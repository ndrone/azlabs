data "terraform_remote_state" "web" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragellkwpibzju"
    container_name       = "tfstate-sc"
    key                  = "web.tfstate"
  }
}