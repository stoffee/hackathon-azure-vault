resource "azurerm_virtual_network" "vault" {
  name                = "acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.vault.location}"
  resource_group_name = "${azurerm_resource_group.vault.name}"
}

resource "azurerm_subnet" "vault" {
  name                 = "acctsub"
  resource_group_name  = "${azurerm_resource_group.vault.name}"
  virtual_network_name = "${azurerm_virtual_network.vault.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "vault" {
  name                = "vault"
  location            = "${azurerm_resource_group.vault.location}"
  resource_group_name = "${azurerm_resource_group.vault.name}"
  allocation_method   = "Static"
  domain_name_label   = "${azurerm_resource_group.vault.name}"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_lb" "vault" {
  name                = "vault"
  location            = "${azurerm_resource_group.vault.location}"
  resource_group_name = "${azurerm_resource_group.vault.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.vault.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = "${azurerm_resource_group.vault.name}"
  loadbalancer_id     = "${azurerm_lb.vault.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = "${azurerm_resource_group.vault.name}"
  name                           = "ssh"
  loadbalancer_id                = "${azurerm_lb.vault.id}"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_probe" "vault" {
  resource_group_name = "${azurerm_resource_group.vault.name}"
  loadbalancer_id     = "${azurerm_lb.vault.id}"
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 8080
}

resource "azurerm_virtual_machine_scale_set" "vault" {
  name                = "myvaultscaleset-1"
  location            = "${azurerm_resource_group.vault.location}"
  resource_group_name = "${azurerm_resource_group.vault.name}"

  # automatic rolling upgrade
  automatic_os_upgrade = false
  upgrade_policy_mode  = "Manual"

#  rolling_upgrade_policy {
#    max_batch_instance_percent              = 20
#    max_unhealthy_instance_percent          = 20
#    max_unhealthy_upgraded_instance_percent = 5
#    pause_time_between_batches              = "PT0S"
#  }

  # required when using rolling upgrade policy
#  health_probe_id = "${azurerm_lb_probe.vault.id}"

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix  = var.vm_name
    admin_username = "azureuser"
    custom_data    = "${base64encode("${data.template_file.setup.rendered}")}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = var.public_key
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "vaultIPConfiguration"
      primary                                = true
      subnet_id                              = "${azurerm_subnet.vault.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
      load_balancer_inbound_nat_rules_ids    = ["${azurerm_lb_nat_pool.lbnatpool.id}"]
    }
  }

  tags = {
    environment = "staging"
  }
}
