provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-RG"
  location = var.node_location
  tags = {
    "Environment" = "Dev"
    "Team"        = "DevOps"
  }
}

# Create a VNet within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-vnet"
  address_space       = var.node_address_space
  location            = var.node_location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a subnets withing the VNet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.node_address_prefix
}

# Create Public IP
resource "azurerm_public_ip" "public_ip" {
  count               = var.node_count
  name                = "${var.resource_prefix}-${format("%02d", count.index)}-publicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "${var.resource_prefix}-${count.index}"
  tags = {
    "environment" = "test"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  count               = var.node_count
  name                = "${var.resource_prefix}-${format("%02d", count.index)}-NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.public_ip.*.id, count.index)
  }
}

# Creating NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    "environment" = "Test"
  }
}

# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual machine creation - Linux
resource "azurerm_virtual_machine" "linux-vm" {
  count                            = var.node_count
  name                             = "${var.resource_prefix}-${format("%02d", count.index)}"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  network_interface_ids            = [element(azurerm_network_interface.nic.*.id, count.index)]
  vm_size                          = "Standard_B2S"
  delete_data_disks_on_termination = true
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "linuxhost"
    admin_username = var.vm_username
    admin_password = var.vm_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    "environment" = "Test"
  }
  connection {
    type     = "ssh"
    host     = azurerm_public_ip.public_ip[count.index].ip_address
    password = var.vm_password
    user     = var.vm_username
  }

  provisioner "file" {
    source      = "post_install/docker.sh"
    destination = "/home/${var.vm_username}/docker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/${var.vm_username}/docker.sh",
      "/home/${var.vm_username}/docker.sh"
    ]
  }
}