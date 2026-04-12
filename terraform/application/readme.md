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
