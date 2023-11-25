
resource "azurerm_resource_group" "pt_resources" {
  name     = "pt_resources_chinmayy"
  location = "Central India"
}

resource "azurerm_virtual_network" "pt_virtual_network" {
  name                = "pt_network_chinmayy"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.pt_resources.location
  resource_group_name = azurerm_resource_group.pt_resources.name
}

resource "azurerm_subnet" "pt_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.pt_resources.name
  virtual_network_name = azurerm_virtual_network.pt_virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pt_public_ip" {
  name                    = "pt_public_ip_chinmayy"
  location                = azurerm_resource_group.pt_resources.location
  resource_group_name     = azurerm_resource_group.pt_resources.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "test"
  }
}


data "azurerm_public_ip" "vm_public_ip" {
  name                = azurerm_public_ip.pt_public_ip.name
  resource_group_name = azurerm_resource_group.pt_resources.name
}

resource "azurerm_network_interface" "pt_network_interface" {
  name                = "pt_nic_chinmayy"
  location            = azurerm_resource_group.pt_resources.location
  resource_group_name = azurerm_resource_group.pt_resources.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pt_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pt_public_ip.id
  }
}

# resource "random_password" "password" {
#   length           = 16
#   special          = true
#   override_special = "!#$%&*()-_=+[]{}<>:?"
# }


resource "azurerm_linux_virtual_machine" "pt_linux_vm" {
  name                = "SnipeITServer"
  resource_group_name = azurerm_resource_group.pt_resources.name
  location            = azurerm_resource_group.pt_resources.location
  size           = "Standard_D2s_v3"
  admin_username = "ubuntu"
  # admin_password = random_password.password.result
  depends_on     = [azurerm_public_ip.pt_public_ip]
 
  network_interface_ids = [
    azurerm_network_interface.pt_network_interface.id,
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("chinmayNewKeys.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

 provisioner "file" {
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("chinmayNewKeys")
    host     = data.azurerm_public_ip.vm_public_ip.ip_address
  }
  source      = "tempo.sh"
  destination = "/home/ubuntu/tempo.sh"
}

provisioner "remote-exec" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("chinmayNewKeys")
    host        = data.azurerm_public_ip.vm_public_ip.ip_address
  }
  inline = [
    "ls -la",
    "sudo chmod +x tempo.sh",
    "sudo ./tempo.sh ${data.azurerm_public_ip.vm_public_ip.ip_address}",
  ]
  
}

}

output "public_ip_address" {
  value = data.azurerm_public_ip.vm_public_ip.ip_address
  # testing the pipeline.
  # testing the pipeline.

}
