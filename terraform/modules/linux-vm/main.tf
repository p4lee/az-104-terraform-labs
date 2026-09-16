resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  size                   = var.size
  zone                   = var.zone
  admin_username         = var.admin_username
  network_interface_ids  = [azurerm_network_interface.this.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  disable_password_authentication = true
  encryption_at_host_enabled      = var.encryption_at_host_enabled

  # 64 GiB Premium SSD is the OS disk size/type that qualifies this VM size
  # for the Azure free account's 750 free hours/month. A bigger or
  # different-tier disk still works, it just isn't covered by the free
  # allowance.
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}

resource "azurerm_managed_disk" "data" {
  count                = var.attach_data_disk ? 1 : 0
  name                 = "${var.name}-data"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  zone                 = var.zone
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.attach_data_disk ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = 0
  caching            = "ReadWrite"
}
