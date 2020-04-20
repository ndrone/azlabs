provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.2.0"
  features {}
}

resource "azurerm_resource_group" "bastion_rg" {
  location = var.location
  name     = "${var.resource-prefix}-rg"
}

resource "azurerm_public_ip" "bastion_ip" {
  location            = var.location
  name                = "${var.resource-prefix}-ip"
  resource_group_name = azurerm_resource_group.bastion_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "${var.resource-prefix}-bh"
  resource_group_name = azurerm_resource_group.bastion_rg.name
  location            = var.location

  ip_configuration {
    name                 = "us2e"
    subnet_id            = data.terraform_remote_state.web.outputs.bastion_host_subnet_us2e
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}