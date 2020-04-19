provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.2.0"
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

variable "vault_location" {}
variable "vault_rg" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "vault_rg" {
  name     = var.vault_rg
  location = var.vault_location
}

resource "azurerm_key_vault" "vault_kv" {
  name                        = "${var.vault_rg}-kv2"
  location                    = azurerm_resource_group.vault_rg.location
  resource_group_name         = azurerm_resource_group.vault_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

//  terraform only needs get access to apply them to other properties
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
    ]

    storage_permissions = [
      "get",
    ]
  }

//  We only want Terraform to create key_vault the access_policy(s) and network change by people within the portal
  lifecycle {
    prevent_destroy = true
    ignore_changes = [access_policy, network_acls]
  }
}