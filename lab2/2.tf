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

provider "azuread" {}


resource "azurerm_management_group" "mg1" {
  name         = "az104-mg1"
  display_name = "az104-mg1"
}

resource "azuread_group" "helpdesk" {
  display_name     = "Help Desk"
  description      = "Help Desk group"
  mail_nickname    = "helpDesk"
  security_enabled = true
}

resource "azurerm_role_assignment" "vm_contributor_mg" {
  scope                = azurerm_management_group.mg1.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_group.helpdesk.id
}

resource "azurerm_role_definition" "custom_support_request" {
  name               = "Custom Support Request" 
  scope              = azurerm_management_group.mg1.id
  description        = "A custom contributor role for support requests"
  assignable_scopes  = [azurerm_management_group.mg1.id]

  permissions {
    actions     = ["*"]
    not_actions = ["Microsoft.Support/register/action"]
  }
}