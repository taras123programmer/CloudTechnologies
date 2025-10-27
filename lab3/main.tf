terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.48"
    }
  }
}

provider "azurerm" {
  features {}
}

#task 1
resource "azurerm_resource_group" "rg" {
  name     = "az104-rg3"
  location = "germanywestcentral"
}

resource "azurerm_managed_disk" "disk1" {
  name                 = "az104-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS" # Standard HDD
  create_option        = "Empty"
  disk_size_gb         = 32
}

#task 2
resource "azurerm_managed_disk" "disk2" {
  name                 = "az104-disk2"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS" # Standard HDD
  create_option        = "Empty"
  disk_size_gb         = 32
}

#task 3
resource "azurerm_storage_account" "sa" {
  name                     = "ivankiv1234" 
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true

  tags = {
    environment = "dev"
  }
}

resource "azurerm_storage_share" "fileshare" {
  name                 = "fs-cloudshell"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 100
}

resource "azurerm_managed_disk" "disk3" {
  name                 = "az104-disk3"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS" # Standard HDD
  create_option        = "Empty"
  disk_size_gb         = 32
}