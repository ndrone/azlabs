provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.0.0"
  features {}
}

variable "web_server_location" {}
variable "web_server_rg" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_name" {}
variable "environment" {}
variable "web_server_count" {}
variable "web_server_subnets" {
  type = list
}
variable "terraform_script_version" {}
variable "domain_name_label" {}

locals {
  web_server_name   = var.environment == "production" ? "${var.web_server_name}-prd" : "${var.web_server_name}-dev"
  build_environment = var.environment == "production" ? "production" : "development"
}

# Create a resource group
resource "azurerm_resource_group" "web_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location

  tags = {
    environment   = local.build_environment
    build-version = var.terraform_script_version
  }
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  address_space       = [var.web_server_address_space]
  # The below subnet doesn't work with a nic
  # subnet {
  #   name           = "${var.resource_prefix}-subnet"
  #   address_prefix = var.web_server_address_prefix
  # }
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-${substr(var.web_server_subnets[count.index], 0, length(var.web_server_subnets[count.index]) - 3)}-subnet"
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = var.web_server_subnets[count.index]
  count                = length(var.web_server_subnets)
}

resource "azurerm_public_ip" "web_server_lb_public_ip" {
  name                = "${var.resource_prefix}-public-ip"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
  domain_name_label   = var.domain_name_label
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.resource_prefix}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_http" {
  name                        = "HTTP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}

resource "azurerm_lb" "web_server_lb" {
  name                = "${var.resource_prefix}-lb"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name

  frontend_ip_configuration {
    name                 = "${var.resource_prefix}-lb-frontend-ip"
    public_ip_address_id = azurerm_public_ip.web_server_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "web_server_lb_backend_pool" {
  name                = "${var.resource_prefix}-lb-backend-pool"
  resource_group_name = azurerm_resource_group.web_server_rg.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
}

resource "azurerm_lb_probe" "web_server_lb_http_probe" {
  name                = "${var.resource_prefix}-lb-http-probe"
  resource_group_name = azurerm_resource_group.web_server_rg.name
  loadbalancer_id     = azurerm_lb.web_server_lb.id
  protocol            = "tcp"
  port                = "80"
}

resource "azurerm_lb_rule" "web_server_lb_http_rule" {
  name                           = "${var.resource_prefix}-lb-http-rule"
  resource_group_name            = azurerm_resource_group.web_server_rg.name
  loadbalancer_id                = azurerm_lb.web_server_lb.id
  protocol                       = "tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  frontend_ip_configuration_name = "${var.resource_prefix}-lb-frontend-ip"
  probe_id                       = azurerm_lb_probe.web_server_lb_http_probe.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id
}

resource "azurerm_windows_virtual_machine_scale_set" "web_server" {
  name                 = "${local.web_server_name}-vmss"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  upgrade_mode         = "Manual"
  instances            = var.web_server_count
  sku                  = "Standard_B1ls"
  computer_name_prefix = "web"
  admin_username       = "adminuser"
  admin_password       = "P@$$w0rd1234!"
  provision_vm_agent   = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  network_interface {
    name                      = "web_server_network_profile"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.web_server_nsg.id

    ip_configuration {
      name                                   = local.web_server_name
      primary                                = true
      subnet_id                              = azurerm_subnet.web_server_subnet.*.id[0]
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id]
    }
  }
}

# resource "azurerm_virtual_machine_scale_set_extension" "web_server_vmss_extension" {
#   name                         = "${local.web_server_name}-vmss-ext"
#   virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.web_server.id
#   publisher                    = "Microsoft.Compute"
#   type                         = "CustomScriptExtension"
#   type_handler_version         = "1.10.5"
#   settings = jsonencode({
#     "fileUris"         = ["https://github.com/eltimmo/learning/blob/master/azureInstallWebServer.ps1"],
#     "commandToExecute" = "start powershell -ExecutionPolicy Unrestricted -File azureInstallWebServer.ps1"
#   })
# }
