resource "azurerm_resource_group" "rg-demo" {
  name     = "${var.rg_name}-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
  }
}