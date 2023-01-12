# generate RSA key
resource "tls_private_key" "new-key" {
  algorithm = "RSA"
}


#-----------------------------------------------------------
# creating a resrouce group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = "West Europe"
}
# creating a netowrk
resource "azurerm_virtual_network" "example" {
  name                = "example-network" # name in the cloud
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
# creating a subnet 
resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "my_public_ip" {
  name                = "hazem-ip-address"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Dynamic"
}
# creating a network interface
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_public_ip.id
  }
}



# creating a VM
resource "azurerm_linux_virtual_machine" "example" {

  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  #  provisioner "local-exec" {
  #   command = "ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N ''"
  # }


  admin_ssh_key {
    username = "adminuser"
    # public_key = file("~/.ssh/id_rsa.pub")
    public_key = tls_private_key.new-key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  connection {
    type        = "ssh"
    user        = "adminuser"
    private_key = tls_private_key.new-key.private_key_openssh
    host        = self.public_ip_address
  }


  provisioner "remote-exec" {
    inline = [
      "bash -c \"echo 'hello Hazem!' > ~/file.txt\""
    ]
  }
}



# provisioner "local-exec" {
#   command = "echo ${self.private_ip} >> private_ips.txt"
# }
