resource "azurerm_virtual_network" "vnet_terra" {
  name                = "${var.vnet_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = [var.vnet_address_space]
}