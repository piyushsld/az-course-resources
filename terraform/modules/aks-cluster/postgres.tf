resource "random_password" "postgres" {
  length           = 24
  special          = true
  override_special = "_%@"
}

resource "azurerm_virtual_network" "postgres" {
  name                = "vnet-postgres"
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = ["10.100.0.0/20"]
}

resource "azurerm_subnet" "postgres" {
  name                 = "postgres-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.postgres.name

  address_prefixes = ["10.100.1.0/24"]

  delegation {
    name = "postgres-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "lddemo.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name

  virtual_network_id = azurerm_virtual_network.postgres.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_aks" {
  name                  = "postgres-aks-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name

  virtual_network_id = azurerm_virtual_network.this.id
}

resource "azurerm_virtual_network_peering" "aks_to_postgres" {
  name                 = "aks-to-postgres"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  remote_virtual_network_id = azurerm_virtual_network.postgres.id
}

resource "azurerm_virtual_network_peering" "postgres_to_aks" {
  name                 = "postgres-to-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.postgres.name

  remote_virtual_network_id = azurerm_virtual_network.this.id
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "pgsql-lddemo"
  resource_group_name = var.resource_group_name
  location            = var.location

  version = "16"

  administrator_login    = "pgadmin"
  administrator_password = random_password.postgres.result

  delegated_subnet_id = azurerm_subnet.postgres.id

  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  storage_mb = 32768

  sku_name = "B_Standard_B1ms"

  public_network_access_enabled = false

  zone = "1"

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres
  ]
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin,
    azurerm_virtual_network_peering.postgres_to_runner,
    azurerm_virtual_network_peering.runner_to_postgres
  ]
}

resource "azurerm_key_vault_secret" "postgres_username" {
  name         = "postgres-username"
  value        = azurerm_postgresql_flexible_server.postgres.administrator_login
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin
  ]
}

resource "azurerm_key_vault_secret" "database_url" {
  name         = "database-url"
  value        = "postgresql://${azurerm_postgresql_flexible_server.postgres.administrator_login}:${random_password.postgres.result}@${azurerm_postgresql_flexible_server.postgres.fqdn}:5432/${azurerm_postgresql_flexible_server_database.appdb.name}"
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_admin,
    azurerm_postgresql_flexible_server_database.appdb
  ]
}

resource "azurerm_postgresql_flexible_server_database" "appdb" {
  name      = "tier3db"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_virtual_network_peering" "postgres_to_runner" {
  name                 = "postgres-to-runner"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.postgres.name

  remote_virtual_network_id = azurerm_virtual_network.gh-runner.id
}

resource "azurerm_virtual_network_peering" "runner_to_postgres" {
  name                 = "runner-to-postgres"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.gh-runner.name

  remote_virtual_network_id = azurerm_virtual_network.postgres.id
}