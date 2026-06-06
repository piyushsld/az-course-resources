resource "azurerm_network_interface" "ghrunner-nic" {
  name                = "ghrunner-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.runner.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ghrunner" {
  name                = "ghrunner-01"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_D2ads_v7"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.ghrunner-nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(local.cloud_init)

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}