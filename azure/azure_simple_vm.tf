variable "location" {
  default = "France Central"
}

variable "prefix" {
  default = "dev"
}

# Configure the Azure Provider
provider "azurerm" {
  version = "=1.24.0"
  subscription_id = "***"
  client_id       = "***"
  client_secret   = "***"
  tenant_id       = "***"
}

# Create a resource group
resource "azurerm_resource_group" "tf-resource-group" {
  name     = "dev"
  location = "${var.location}"
}

# Create a virtual network
resource "azurerm_virtual_network" "tf-network" {
    name                = "dev-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.tf-resource-group.name}"
    tags {
        environment = "dev"
    }
}

# Create subnet
resource "azurerm_subnet" "tf-subnet" {
    name                 = "dev-subnet"
    resource_group_name  = "${azurerm_resource_group.tf-resource-group.name}"
    virtual_network_name = "${azurerm_virtual_network.tf-network.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IP address
resource "azurerm_public_ip" "tf-publicip" {
    name                         = "dev-pubip"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.tf-resource-group.name}"
    allocation_method            = "Dynamic"
    tags {
        environment = "dev"
    }
}

# Create a network security-group
resource "azurerm_network_security_group" "tf-nsg" {
    name                = "myNetworkSecurityGroup"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.tf-resource-group.name}"

    security_rule {
        name                       = "ssh"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefixes    = ["***", "***"]
        destination_address_prefix = "*"
    }
    tags {
        environment = "dev"
    }
}

# Create a network interface / port
resource "azurerm_network_interface" "tf-nic" {
    name                = "dev-nic"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.tf-resource-group.name}"
    network_security_group_id = "${azurerm_network_security_group.tf-nsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.tf-subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.tf-publicip.id}"
    }
    tags {
        environment = "dev"
    }
}

# Create a VM
resource "azurerm_virtual_machine" "tf-vm" {
  name                  = "${var.prefix}vm"
  location              = "${azurerm_resource_group.tf-resource-group.location}"
  resource_group_name   = "${azurerm_resource_group.tf-resource-group.name}"
  network_interface_ids = ["${azurerm_network_interface.tf-nic.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "testvm"
    admin_username = "ubuntu"
  }
  os_profile_linux_config {
      disable_password_authentication = true
      ssh_keys {
          path     = "/home/ubuntu/.ssh/authorized_keys"
          key_data = "***"
      }
  }
  tags = {
    environment = "dev"
  }
}
