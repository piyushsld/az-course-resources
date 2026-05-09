locals {
  env = terraform.workspace
  env_config = {
    dev  = { vm_size = "Standard_B1s", vm_count = 1, address_space = "10.0.1.0/16" }
    prod = { vm_size = "Standard_B2s", vm_count = 2, address_space = "10.0.2.0/16" }
  }
  config = local.env_config[local.env]
  location = local.env == "dev" ? "canadacentral" : "eastus"
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources-${local.env}"
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network-${local.env}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal-${local.env}"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = [cidrsubnet(local.config.address_space, 8, 1)]
}

resource "azurerm_network_interface" "example" {
  count               = local.config.vm_count
  name                = "example-nic-${local.env}-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal-${count.index}"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  count               = local.config.vm_count
  name                = "example-machine-${local.env}-${count.index}"
  resource_group_name = azurerm_resource_group.example.name
  location            = var.location
  size                = local.config.vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/piyushsharma/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}