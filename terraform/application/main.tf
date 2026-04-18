locals {
  env = terraform.workspace
  env_config = {
    dev  = { vm_size = "Standard_B1s", vm_count = 1, address_space = "10.1.0.0/16" }
    prod = { vm_size = "Standard_B2s", vm_count = 2, address_space = "10.2.0.0/16" }
  }
  config   = local.env_config[terraform.workspace]
  location = local.env == "dev" ? "canadacentral" : "eastus"
}

resource "azurerm_resource_group" "example" {
  name     = "tf-demo-${local.env}"
  location = local.location
}

resource "azurerm_user_assigned_identity" "example" {
  location            = local.location
  name                = "tf-demo-${local.env}"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_storage_account" "example" {
  name                     = "stgactlddevops01${local.env}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    service = "data-engineering"
    env     = local.env
  }
}

resource "azurerm_user_assigned_identity" "demo2" {
  location            = local.location
  name                = "tf-demo2-${local.env}"
  resource_group_name = azurerm_resource_group.example.name
}

# data "azurerm_resource_group" "demo2" {
#   name = "tf-demo2-${local.env}"
# }

# resource "azurerm_user_assigned_identity" "mg-demo2" {
#   location            = "Canada Central"
#   name                = "mg-demo2"
#   resource_group_name = data.azurerm_resource_group.demo2.name
# }

resource "azurerm_virtual_network" "example" {
  name                = "${local.env}-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "${local.env}"
  }
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = [cidrsubnet(local.config.address_space, 8, 1)]
}

resource "azurerm_network_interface" "example" {
  count               = local.config.vm_count
  name                = "example-nic-${local.env}-${count.index}"
  location            = local.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  count               = local.config.vm_count
  name                = "example-machine-${local.env}-${count.index}"
  resource_group_name = azurerm_resource_group.example.name
  location            = local.location
  size                = local.config.vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]

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