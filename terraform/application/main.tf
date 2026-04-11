resource "azurerm_resource_group" "example" {
  name     = "tf-demo"
  location = "Canada Central"
}

resource "azurerm_user_assigned_identity" "example" {
  location            = "Canada Central"
  name                = "tf-demo"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_storage_account" "example" {
  name                     = "stgactlddevops01"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = "Canada Central"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    service = "data-engineering"
  }
}

resource "azurerm_user_assigned_identity" "demo2" {
  location            = "Canada Central"
  name                = "tf-demo2"
  resource_group_name = azurerm_resource_group.example.name
}

data "azurerm_resource_group" "demo2" {
  name = "tf-demo2"
}

resource "azurerm_user_assigned_identity" "mg-demo2" {
  location            = "Canada Central"
  name                = "mg-demo2"
  resource_group_name = data.azurerm_resource_group.demo2.name
}