# Set provider and terraform version

provider "azurerm" {
  version = "~> 1.1"
}

terraform {
  required_version = "0.11.5"
}

#Create resource group

resource "azurerm_resource_group" "tmp_rg" {
  name     = "${var.prefix}-${var.tmp_resource_group_name}"
  location = "${var.location}"
}

# Create Vnet

resource "azurerm_virtual_network" "tmp_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["${var.tmp_vnet}"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.tmp_rg.name}"
}

# Create Subnet

resource "azurerm_subnet" "tmp_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = "${azurerm_resource_group.tmp_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.tmp_vnet.name}"
  address_prefix       = "${var.tmp_subnet}"
}

# Provisioning public IP

resource "azurerm_public_ip" "tmp_public_ip" {
  name                         = "${var.prefix}-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.tmp_rg.name}"
  public_ip_address_allocation = "dynamic"
}

# Provisioning eth (w/ public IP)

resource "azurerm_network_interface" "tmp_nic" {
  name                = "${var.prefix}-${var.tmp_nic_name}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.tmp_rg.name}"

  ip_configuration {
    name                          = "${var.prefix}-nic-config"
    subnet_id                     = "${azurerm_subnet.tmp_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.tmp_public_ip.id}"
  }
}

# Create virutal machine

resource "azurerm_virtual_machine" "tmp_vm" {
  name                  = "${var.prefix}-vm"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.tmp_rg.name}"
  network_interface_ids = ["${azurerm_network_interface.tmp_nic.id}"]
  vm_size               = "${var.tmp_vm_size}"

  # This means the OS Disk will be deleted when Terraform destroys the Virtual Machine
  # NOTE: This is used here only for a tmp environment
  delete_os_disk_on_termination = true


  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
  publisher = "${var.image_publisher}"
  offer     = "${var.image_offer}"
  sku       = "${var.image_sku}"
  version   = "${var.image_version}"
  }

  os_profile {
    admin_username = "${var.prefix}-${var.tmp_user}"
    admin_password = ""
    computer_name  = "${var.prefix}-vm"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.tmp_user}/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }
}

output "public_ip_id" {
  description = "id of the public ip address provisoned."
  value       = "${azurerm_public_ip.tmp_public_ip.*.id}"
}
output "public_ip_address" {
  description = "The actual ip address allocated for the resource."
  value       = "${azurerm_public_ip.tmp_public_ip.*.ip_address}"
}
