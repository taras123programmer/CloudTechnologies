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
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "azapi" {}

#Task 1: Assign tags via the Azure portal

resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg2"
  location = "germanywestcentral"

  tags = {
    "Cost Center" = "000"
  }
}


#Task 2: Enforce tagging via an Azure Policy


data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}


resource "azurerm_resource_group_policy_assignment" "inherit_tag" {
  name                 = "inherit-cc-tag"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id
  display_name         = "Inherit the Cost Center tag and its value 000 from the resource group if missing"
  description          = "Inherit the Cost Center tag and its value 000 from the resource group if missing"

  parameters = jsonencode({
    tagName = { value = "CostCenter" }
  })

  identity {
    type = "SystemAssigned"
  }

  location = azurerm_resource_group.rg2.location

  depends_on = [azurerm_resource_group.rg2]
}

resource "azurerm_resource_policy_remediation" "inherit_tag" {
  name                    = "remediate-cc-tag"
  resource_id             = azurerm_resource_group.rg2.id
  policy_assignment_id    = azurerm_resource_group_policy_assignment.inherit_tag.id
  resource_discovery_mode = "ReEvaluateCompliance"

  depends_on = [azurerm_resource_group_policy_assignment.inherit_tag]
}

resource "azurerm_storage_account" "stg" {
  name                     = "ivankiv123"
  resource_group_name      = azurerm_resource_group.rg2.name
  location                 = azurerm_resource_group.rg2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [
    azurerm_resource_group_policy_assignment.inherit_tag,
    azurerm_resource_policy_remediation.inherit_tag
  ]
}

resource "azurerm_management_lock" "lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg2.id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of the resource group"
}