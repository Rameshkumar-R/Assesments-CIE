#Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "linuxvmgrp" {
    name     = "myLinuxVMGroup"
    location = "eastus"

    tags = {
        
        environment = "Production"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "mylinuxvmnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.linuxvmgrp.name

    tags = {
        environment = "Production"
    }
}

# Create subnet
resource "azurerm_subnet" "myvmsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.linuxvmgrp.name
    virtual_network_name = azurerm_virtual_network.mylinuxvmnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myvm1publicip" {
    name                         = "myPublicIP1"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.linuxvmgrp.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Production"
    }
}

resource "azurerm_public_ip" "myvm2publicip" {
    name                         = "myPublicIP2"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.linuxvmgrp.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Production"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "mylinuxvmnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.linuxvmgrp.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Production"
    }
}

# Create network interface
resource "azurerm_network_interface" "myvm1nic" {
    name                      = "myNIC1"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.linuxvmgrp.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myvmsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myvm1publicip.id
    }

    tags = {
        environment = "Production"
    }
}

resource "azurerm_network_interface" "myvm2nic" {
    name                      = "myNIC2"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.linuxvmgrp.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myvmsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myvm2publicip.id
    }

    tags = {
        environment = "Production"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "mylinuxsg1" {
    network_interface_id      = azurerm_network_interface.myvm1nic.id
    network_security_group_id = azurerm_network_security_group.mylinuxvmnsg.id
}

resource "azurerm_network_interface_security_group_association" "mylinuxsg2" {
    network_interface_id      = azurerm_network_interface.myvm2nic.id
    network_security_group_id = azurerm_network_security_group.mylinuxvmnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.linuxvmgrp.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.linuxvmgrp.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Production"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "myvm1" {
    name                  = "myVM1"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.linuxvmgrp.name
    network_interface_ids = [azurerm_network_interface.myvm1nic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk1"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "myvm1"
    admin_username = var.admin_username
    admin_password = var.admin_password
    disable_password_authentication = false
   
    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Production"
    }
}

resource "azurerm_linux_virtual_machine" "myvm2" {
    name                  = "myVM2"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.linuxvmgrp.name
    network_interface_ids = [azurerm_network_interface.myvm2nic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk2"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "myvm2"
    admin_username = var.admin_username
    admin_password = var.admin_password
    disable_password_authentication = false

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Production"
    }
}


output "vm1_ip" {
  value = azurerm_linux_virtual_machine.myvm1.public_ip_address
}

output "vm2_ip" {
  value = azurerm_linux_virtual_machine.myvm2.public_ip_address
}

output "vm1_pass" {
  value = var.admin_password
  sensitive = true
}

output "vm2_pass" {
  value = var.admin_password
  sensitive = true
}
