resource "azurerm_resource_group" "rg" {
  name     = "rg-terra-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
  }
}