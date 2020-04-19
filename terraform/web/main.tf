provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.2.0"
  features {}
}

module "web_us2e" {
  source = "../modules/web"
  admin_password = data.azurerm_key_vault_secret.admin_password.value
  environment = var.environment
  resource_prefix = "${var.resource_prefix}-us2e"
  terraform_script_version = var.terraform_script_version
  web_server_address_space = "1.0.0.0/22"
  web_server_count = var.web_server_count
  web_server_location = "eastus2"
  web_server_name = var.web_server_name
  web_server_rg = "${var.web_server_rg}-us2e"
  web_server_subnets = ["1.0.1.0/24", "1.0.2.0/24"]
}

module "web_us2w" {
  source = "../modules/web"
  admin_password = data.azurerm_key_vault_secret.admin_password.value
  environment = var.environment
  resource_prefix = "${var.resource_prefix}-us2w"
  terraform_script_version = var.terraform_script_version
  web_server_address_space = "2.0.0.0/22"
  web_server_count = var.web_server_count
  web_server_location = "westus2"
  web_server_name = var.web_server_name
  web_server_rg = "${var.web_server_rg}-us2w"
  web_server_subnets = ["2.0.1.0/24", "2.0.2.0/24"]
}