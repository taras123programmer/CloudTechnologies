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

resource "azurerm_resource_group" "rg" {
  name     = "az104-rg6"
  location = var.location
}


resource "azurerm_virtual_network" "vnet" {
  name                = "az104-06-vnet1"
  address_space       = ["10.60.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_0" {
  name                 = "subnet_0"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.60.0.0/24"]
}

resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet_1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.60.1.0/24"]
}

resource "azurerm_subnet" "subnet_2" {
  name                 = "subnet_2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.60.2.0/24"]
}


resource "azurerm_subnet" "appgw_subnet" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.60.3.224/27"]
}


resource "azurerm_network_interface" "nic_0" {
  name                = "az104-06-nic_0"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_0.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic_1" {
  name                = "az104-06-nic_1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "nic_2" {
  name                = "az104-06-nic_2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_2.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_windows_virtual_machine" "vm0" {
  name                = "az104-06-vm0"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic_0.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "az104-06-vm1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic_1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "az104-06-vm2"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic_2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "az104-06-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_0_nsg" {
  network_interface_id      = azurerm_network_interface.nic_0.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_1_nsg" {
  network_interface_id      = azurerm_network_interface.nic_1.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_network_interface_security_group_association" "nic_2_nsg" {
  network_interface_id      = azurerm_network_interface.nic_2.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_public_ip" "lb_pip" {
  name                = "az104-lbpip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "az104-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration { 
    name                 = "az104-fe"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  name            = "az104-be"
  loadbalancer_id = azurerm_lb.lb.id
}


resource "azurerm_network_interface_backend_address_pool_association" "vm0_assoc" {
  network_interface_id    = azurerm_network_interface.nic_0.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm1_assoc" {
  network_interface_id    = azurerm_network_interface.nic_1.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_pool.id
}

resource "azurerm_lb_probe" "lb_probe" {
  name                = "az104-hp"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = "az104-lbrule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "az104-fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
}


resource "azurerm_public_ip" "appgw_pip" {
  name                = "az104-gwpip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "az104-appgw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendIP"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  backend_address_pool {
    name         = "az104-appgwbe"
    ip_addresses = [
      azurerm_network_interface.nic_1.private_ip_address,
      azurerm_network_interface.nic_2.private_ip_address
    ]
  }

  backend_address_pool {
    name         = "az104-imagebe"
    ip_addresses = [azurerm_network_interface.nic_1.private_ip_address]
  }

  backend_address_pool {
    name         = "az104-videobe"
    ip_addresses = [azurerm_network_interface.nic_2.private_ip_address]
  }

  backend_http_settings {
    name                  = "az104-http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "az104-listener"
    frontend_ip_configuration_name = "frontendIP"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  url_path_map {
    name                                = "az104-pathmap"
    default_backend_address_pool_name   = "az104-appgwbe"
    default_backend_http_settings_name  = "az104-http"

        path_rule {
      name                       = "images"
      paths                      = ["/image/*"]
      backend_address_pool_name = "az104-imagebe"
      backend_http_settings_name = "az104-http"
    }

    path_rule {
      name                       = "videos"
      paths                      = ["/video/*"]
      backend_address_pool_name = "az104-videobe"
      backend_http_settings_name = "az104-http"
    }
  }

  request_routing_rule {
    name                  = "az104-gwrule"
    rule_type             = "PathBasedRouting"
    http_listener_name    = "az104-listener"
    url_path_map_name     = "az104-pathmap"
    priority              = 10
  }
}