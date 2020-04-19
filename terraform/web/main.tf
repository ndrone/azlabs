provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.2.0"
  features {}
}

module "web_us2e" {
  source                   = "../modules/web"
  admin_password           = data.azurerm_key_vault_secret.admin_password.value
  environment              = var.environment
  resource_prefix          = "${var.resource_prefix}-us2e"
  terraform_script_version = var.terraform_script_version
  web_server_address_space = "1.0.0.0/22"
  web_server_count         = var.web_server_count
  web_server_location      = "eastus2"
  web_server_name          = var.web_server_name
  web_server_rg            = "${var.web_server_rg}-us2e"
  web_server_subnets       = {
    web-server         = "1.0.1.0/24"
    AzureBastionSubnet = "1.0.2.0/24"
  }
  domain_name_label        = var.domain_name_label
}

module "web_us2w" {
  source                   = "../modules/web"
  admin_password           = data.azurerm_key_vault_secret.admin_password.value
  environment              = var.environment
  resource_prefix          = "${var.resource_prefix}-us2w"
  terraform_script_version = var.terraform_script_version
  web_server_address_space = "2.0.0.0/22"
  web_server_count         = var.web_server_count
  web_server_location      = "westus2"
  web_server_name          = var.web_server_name
  web_server_rg            = "${var.web_server_rg}-us2w"
  web_server_subnets       = {
    web-server         = "2.0.1.0/24"
    AzureBastionSubnet = "2.0.2.0/24"
  }
  domain_name_label        = var.domain_name_label
}

resource "azurerm_resource_group" "global_rg" {
  location = "eastus2"
  name     = "traffic-manager-rg"
}

resource "azurerm_traffic_manager_profile" "traffic_manager" {
  name                   = "${var.resource_prefix}-tm"
  resource_group_name    = azurerm_resource_group.global_rg.name
  traffic_routing_method = "Weighted"
  dns_config {
    relative_name = var.domain_name_label
    ttl           = 100
  }
  monitor_config {
    port     = 80
    protocol = "http"
    path     = "/"
  }
}

resource "azurerm_traffic_manager_endpoint" "traffic_manage_us2e" {
  name                = "${var.resource_prefix}-us2e-endpoint"
  profile_name        = azurerm_traffic_manager_profile.traffic_manager.name
  resource_group_name = azurerm_resource_group.global_rg.name
  target_resource_id  = module.web_us2e.web_server_lb_public_ip_id
  type                = "azureEndpoints"
  weight              = 100
}

resource "azurerm_traffic_manager_endpoint" "traffic_manage_us2w" {
  name                = "${var.resource_prefix}-us2w-endpoint"
  profile_name        = azurerm_traffic_manager_profile.traffic_manager.name
  resource_group_name = azurerm_resource_group.global_rg.name
  target_resource_id  = module.web_us2w.web_server_lb_public_ip_id
  type                = "azureEndpoints"
  weight              = 100
}