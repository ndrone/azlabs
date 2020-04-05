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

# Create a resource group
resource "azurerm_resource_group" "web_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location
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

resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${var.resource_prefix}-public-ip"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.resource_prefix}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
  count                       = var.environment == "production" ? 0 : 1
}

resource "azurerm_windows_virtual_machine_scale_set" "web_server" {
  name                = "${var.web_server_name}-vmss"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  upgrade_mode        = "Manual"
  instances           = var.web_server_count
  sku                 = "Standard_B1ls"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"

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
      name      = var.web_server_name
      primary   = true
      subnet_id = azurerm_subnet.web_server_subnet.*.id[0]
    }
  }
}
