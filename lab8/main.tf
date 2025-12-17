terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.52"
    }
  }
}


provider "azurerm" {
  features {}
  subscription_id = "bc1a0270-6de3-4984-9e04-aec67432b9ef"
}

resource "azurerm_resource_group" "rg" {
  location   = var.location
  name       = "az104-rg8"
  tags       = {}
}


resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet_1" {
  name                 = "subnet_1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip_1" {
  name                = "public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic_1" {
  name                = "nic_1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  lifecycle {
    prevent_destroy = true
  }

  ip_configuration {
    name                          = "ip-config_1"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_1.id
  }
}

resource "azurerm_public_ip" "public_ip_2" {
  name                = "public-ip_2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic_2" {
  name                = "nic_2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  lifecycle {
    prevent_destroy = true
  }

  ip_configuration {
    name                          = "ip-config_2"
    subnet_id                     = azurerm_subnet.subnet_1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_2.id
  }
}


resource "azurerm_windows_virtual_machine" "vm1" {
  name                  = "az104-vm1"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.disk_size
  zone     = "1"
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

  admin_username = "localadmin"
  admin_password =  var.admin_password


  tags = {
    environment = "production"
  }
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                  = "az104-vm2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_2.id]
  size                  = var.disk_size
  zone     = "2"

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

  admin_username = "adminuser"
  admin_password = "P@ssw0rd1234!"

}

resource "azurerm_managed_disk" "disk1" {
  name                 = "vm1-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
  zone = "1"
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment" {
  virtual_machine_id = azurerm_windows_virtual_machine.vm1.id
  managed_disk_id    = azurerm_managed_disk.disk1.id
  lun                = 0
  caching            = "None"
}

#Task 3

resource "azurerm_virtual_network" "vmss_vnet" {
  name                = "vmss-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = ["10.82.0.0/20"]
}

resource "azurerm_subnet" "subnet_0" {
  name                 = "subnet_0"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name

  address_prefixes = ["10.82.0.0/24"]
}

resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "vmss-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"

  source_port_range           = "*"
  destination_port_range      = "80"

  source_address_prefix       = "*"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vmss_nsg.name
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet_0.id
  network_security_group_id = azurerm_network_security_group.vmss_nsg.id
}

resource "azurerm_public_ip" "vmss_lb_ip" {
  name                = "vmss-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_lb" "vmss_lb" {
  name                = "vmss-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicFrontend"
    public_ip_address_id = azurerm_public_ip.vmss_lb_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "vmss_bepool" {
  loadbalancer_id     = azurerm_lb.vmss_lb.id
  name                = "vmss-bepool"
}

resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id     = azurerm_lb.vmss_lb.id
  name                = "http-probe"
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}


resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.vmss_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicFrontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vmss_bepool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = "vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku       = var.disk_size
  instances = 2                    
  zones     = ["1", "2", "3"]

  admin_username = "localadmin"
  admin_password = var.admin_password

  upgrade_mode = "Manual"          

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                    = "ipconfig"
      primary                                 = true
      subnet_id                               = azurerm_subnet.subnet_0.id
      load_balancer_backend_address_pool_ids  = [azurerm_lb_backend_address_pool.vmss_bepool.id]

    }

  }

}

# Task 4

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss1-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss.id
  location            = azurerm_resource_group.rg.location

  enabled = true

  profile {
    name = "cpu-based-scale"

    capacity {
      default = 2  # Default number of VM instances
      minimum = 2  # Minimum number of VM instances
      maximum = 10 # Maximum number of VM instances
    }

    # Scale OUT: CPU > 70%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "PercentChangeCount"
        value     = 50
        cooldown  = "PT5M"
      }
    }

    # Scale IN: CPU < 30%
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "PercentChangeCount"
        value     = 20
        cooldown  = "PT5M"
      }
    }
  }
}

