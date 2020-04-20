// todo connect to the vault remote_state like bastion does
data "azurerm_key_vault" "key_vault" {
  name                = "vault-rg-kv3"
  resource_group_name = "vault-rg"
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password"
  key_vault_id = data.azurerm_key_vault.key_vault.id
}