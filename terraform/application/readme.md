# Variable demo use-cases  

## String type (Most common)  

''  
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
''  

main.tf resource - resource group, storage account  

## bool - Used for enabling/disabling feature or resource  

''  
variable "enable_encryption" {  
  type    = bool  
  default = true  
}  
''  

main.tf resource -  
  
''  
resource "azurerm_storage_account" "sa" {  
  name                = "sttfstate001"  
  resource_group_name = azurerm_resource_group.rg.name  
  location            = var.location  
  account_tier        = "Standard"  
  account_replication_type = "LRS"  
  
  # Feature‑like flag: enable/disable encryption for blob services  
  blob_encryption_enabled    = var.enable_encryption  
  nfs_v3_enabled             = false  
  min_tls_version            = "TLS1_2"  
}  
''  

## Map - used for complete set of values  
''
variable "env_tags" {  
  type = map(string)  
  default = {  
    "Environment" = "dev"  
    "Owner"       = "devops-team"  
    "CostCenter"  = "1001"  
  }  
}  
''  

main.tf resource - managed identity, storage account  

## List - used to pass list of resources  

''
variable "subnet_cidrs" {  
  type    = list(string)  
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  
}  
''  