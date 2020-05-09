provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.2.0"
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "java_web_rg" {
  name     = "java-web-app-rg"
  location = "centralus"
}

resource "azurerm_app_service_plan" "java_web_plan" {
  name                = "java-web-app-plan"
  location            = azurerm_resource_group.java_web_rg.location
  resource_group_name = azurerm_resource_group.java_web_rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "java_web_service" {
  name                = "java-web-app-service"
  location            = azurerm_resource_group.java_web_rg.location
  resource_group_name = azurerm_resource_group.java_web_rg.name
  app_service_plan_id = azurerm_app_service_plan.java_web_plan.id

  site_config {
    java_version = "11"
  }
}