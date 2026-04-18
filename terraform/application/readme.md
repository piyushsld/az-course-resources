# Variable demo use-cases  

## String type (Most common)  

```  
variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-demo"
}

variable "storage_account_tier" {
  type    = string
  default = "Standard"
}
```  

main.tf resource - resource group, storage account  

## bool - Used for enabling/disabling feature or resource  

```  
variable "enable_encryption" {
  type    = bool
  default = true
}
```  

main.tf resource -  
  
```  
resource "azurerm_storage_account" "example" {
  count                             = var.create_stgaccnt ? 1 : 0
  name                              = "storageaccountname"
  resource_group_name               = local.rg_name
  location                          = var.region
  account_tier                      = var.account_tier
  account_replication_type          = "GRS"
  infrastructure_encryption_enabled = var.enable_encryption
  nfsv3_enabled                     = false
  min_tls_version                   = "TLS1_2"

  tags = var.tags
}
```  

## Map - used for complete set of values  
```  
variable "env_tags" {
  type = map(string)
  default = {
    "Environment" = "dev"
    "Owner"       = "devops-team"
    "CostCenter"  = "1001"
  }
}
```  

main.tf resource - managed identity, storage account  

## List - used to pass list of resources  

```  
variable "subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
```  

main.tf resource  
```
resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-network"
  location            = var.region
  resource_group_name = local.rg_name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  dynamic "subnet" {
    for_each = var.subnet_cidrs
    content {
      name             = "subnet-${index(var.subnet_cidrs, subnet.value) + 1}"
      address_prefixes = [subnet.value]
    }
  }

  tags = var.tags
}
```

# azurerm backend config  
```
terraform {
  required_version = ">= 1.14.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.68.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = ""
    storage_account_name = ""
    container_name       = ""
    key                  = ""
  }
}
```
  
# Lifecycle meta-arguments  
  
## create_before_destroy  
```
resource "azurerm_linux_virtual_machine" "web" {
  name                = "vm-web-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  
  # Create new VM before destroying old one (no downtime)
  lifecycle {
    create_before_destroy = true
  }
  
  # ... rest of VM config
}
```
  
## prevent_destroy  

```
resource "azurerm_resource_group" "prod_rg" {
  count    = var.environment == "prod" ? 1 : 0
  name     = "rg-prod-critical"
  location = var.location
  
  # Terraform refuses to destroy this resource
  lifecycle {
    prevent_destroy = true
  }
}
```
  
## ignore_changes  
```
resource "azurerm_linux_virtual_machine_scale_set" "web" {
  name                = "vmss-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.vm_size
  instances           = var.vm_count
  
  # Ignore changes to tags (managed by external policy)
  # and instances (auto-scaling changes them)
  lifecycle {
    ignore_changes = [
      tags,
      instances
    ]
  }
}
```
  
## replace_triggered_by  
```
resource "azurerm_subnet" "app" {
  name                 = "snet-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
  
  # Replace subnet when VNet address_space changes
  lifecycle {
    replace_triggered_by = [
      azurerm_virtual_network.main.address_space
    ]
  }
}
```
  
## precondition  
```
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_space]
  
  lifecycle {
    precondition {
      condition     = can(cidrsubnet(var.address_space, 8, 1))
      error_message = "address_space must be valid CIDR (e.g. 10.0.0.0/16)."
    }
  }
}
```
  
## postcondition  
```
resource "azurerm_linux_virtual_machine" "web" {
  # ... VM config
  
  lifecycle {
    postcondition {
      condition     = self.size != "Standard_B1s" || var.environment != "prod"
      error_message = "Production VMs cannot use Standard_B1s (too small)."
    }
  }
}
```
  
# for_each meta-argument  
  
## Map of Strings - Multiple Resource Groups  
```
# variables.tf
variable "resource_groups" {
  type = map(string)
  default = {
    app    = "canadacentral"
    db     = "eastus"
    shared = "eastus2"
  }
}

# main.tf
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups
  
  name     = "rg-${each.key}-${var.environment}"
  location = each.value
  
  tags = {
    Environment = var.environment
    Purpose     = each.key
  }
}
```
  
## Set of Strings - Multiple Subnets. 
```
resource "azurerm_subnet" "subnets" {
  for_each             = toset(["web", "db", "app"])
  name                 = "${each.value}-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg["app"].name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.${each.value == "web" ? 1 : each.value == "db" ? 2 : 3}.0/24"]
}
```
  
## Map of Objects - VMs with Different Sizes
```
variable "vms" {
  type = map(object({
    size  = string
    count = number
  }))
  default = {
    frontend = {
      size  = "Standard_B2s"
      count = 2
    }
    backend = {
      size  = "Standard_D2s_v3" 
      count = 1
    }
  }
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each            = var.vms
  name                = "${each.key}-vm-${var.environment}"
  location            = azurerm_resource_group.rg["app"].location
  resource_group_name = azurerm_resource_group.rg["app"].name
  size                = each.value.size
  
  # ... rest of VM config
}
```
  