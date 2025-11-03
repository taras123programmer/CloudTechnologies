terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "CoreServicesVnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
}


resource "azurerm_subnet" "shared" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.10.0/24"]
}

resource "azurerm_subnet" "db" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.20.0/24"]
}


resource "azurerm_virtual_network" "vnet2" {
  name                = "ManufacturingVnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.30.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "SensorSubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.30.10.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "SensorSubnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.30.20.0/24"]
}


resource "azurerm_application_security_group" "asg_web" {
  name                = "asg-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}


resource "azurerm_network_security_group" "my_nsg" {
  name                = "myNSGSecure"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_subnet_network_security_group_association" "shared_nsg_assoc" {
  subnet_id                 = azurerm_subnet.shared.id
  network_security_group_id = azurerm_network_security_group.my_nsg.id
}


resource "azurerm_network_security_rule" "allow_asg" {
  name                        = "AllowASG"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_ranges           = ["0-65535"]
  destination_port_ranges      = ["80", "443"]
  source_application_security_group_ids = [
    azurerm_application_security_group.asg_web.id
  ]
  destination_address_prefix   = "*"
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.my_nsg.name
}

resource "azurerm_network_security_rule" "deny_internet" {
  name                        = "DenyInternet"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_ranges           = ["0-65535"]
  destination_port_ranges      = ["0-65535"]
  source_address_prefix        = "*"
  destination_address_prefix    = "Internet"  # Azure Service Tag
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.my_nsg.name
}


resource "azurerm_dns_zone" "contoso_zone" {
  name = "contoso123_ivankiv.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "www_record" {
  name                = "www"
  zone_name           = azurerm_dns_zone.contoso_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 1

  records = ["10.1.1.4"]
}

resource "azurerm_private_dns_zone" "private_zone" {
  name                = "private.contoso.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "manufacturing_link" {
  name                  = "manufacturing-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet2.id
  registration_enabled  = true
}


resource "azurerm_private_dns_a_record" "sensorvm_record" {
  name                = "sensorvm"
  zone_name           = azurerm_private_dns_zone.private_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 1
  records             = ["10.1.1.4"]
}