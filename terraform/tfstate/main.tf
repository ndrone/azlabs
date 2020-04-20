provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.2.0"
  features {}
}

provider "random" {
  version = "2.2"
}

variable "tfstate_location" {}
variable "resource_prefix" {}


resource "azurerm_resource_group" "tfstate_rg" {
  name     = "${var.resource_prefix}-rg"
  location = var.tfstate_location
}

resource "random_string" "random" {
  length  = 10
  upper   = false
  special = false
  number  = false
}

resource "azurerm_storage_account" "storage_account" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.tfstate_location
  name                     = "tfstatestorage${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
}

// This what holds our TF states. We should never want this deleted.
resource "azurerm_storage_container" "tf_state_sc" {
  name                = "${var.resource_prefix}-sc"
  storage_account_name = azurerm_storage_account.storage_account.name
  lifecycle {
    prevent_destroy = true
  }
}