output "vault_resource_group" {
  value = azurerm_resource_group.vault_rg.name
}

output "key_vault_name" {
  value = azurerm_key_vault.vault_kv.name
}
