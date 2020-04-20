output "tfstate_resource_group" {
  value = azurerm_resource_group.tfstate_rg.name
}

output "tfstate_storage_account" {
  value = azurerm_storage_account.storage_account.name
}

output "tfstate_storage_container" {
  value = azurerm_storage_container.tf_state_sc.name
}