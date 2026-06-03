# SSH ključ za sve VM-ove
resource "azurerm_ssh_public_key" "techsprint_key" {
  name                = "ssh-techsprint-testing"
  resource_group_name = azurerm_resource_group.lead_rg.name
  location            = var.location
  public_key          = file("~/.ssh/id_rsa.pub")
}

# Public IP za Jump Host svakog developera
resource "azurerm_public_ip" "jumphost_pip" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                = "pip-jumphost-${each.key}-testing"
  resource_group_name = azurerm_resource_group.developer_rg[each.key].name
  location            = var.location
  allocation_method   = "Static"

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Network Interface za Jump Host
resource "azurerm_network_interface" "jumphost_nic" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                = "nic-jumphost-${each.key}-testing"
  resource_group_name = azurerm_resource_group.developer_rg[each.key].name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev_subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumphost_pip[each.key].id
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Jump Host VM za svakog developera
resource "azurerm_linux_virtual_machine" "jumphost_vm" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                = "vm-jumphost-${each.key}-testing"
  resource_group_name = azurerm_resource_group.developer_rg[each.key].name
  location            = var.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.jumphost_nic[each.key].id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.techsprint_key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Network Interface za Moodle VM-ove (2 po developeru)
resource "azurerm_network_interface" "moodle_nic" {
  for_each = {
    for pair in flatten([
      for dev in local.developers : [
        for i in range(2) : {
          key = "${dev.ime}-${dev.prezime}-moodle${i + 1}"
          dev = dev
        }
      ]
    ]) : pair.key => pair
  }

  name                = "nic-${each.key}-testing"
  resource_group_name = azurerm_resource_group.developer_rg["${each.value.dev.ime}-${each.value.dev.prezime}"].name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev_subnet["${each.value.dev.ime}-${each.value.dev.prezime}"].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Moodle VM-ovi (2 po developeru)
resource "azurerm_linux_virtual_machine" "moodle_vm" {
  for_each = {
    for pair in flatten([
      for dev in local.developers : [
        for i in range(2) : {
          key = "${dev.ime}-${dev.prezime}-moodle${i + 1}"
          dev = dev
        }
      ]
    ]) : pair.key => pair
  }

  name                = "vm-moodle-${each.key}-testing"
  resource_group_name = azurerm_resource_group.developer_rg["${each.value.dev.ime}-${each.value.dev.prezime}"].name
  location            = var.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.moodle_nic[each.key].id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.techsprint_key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Data disk za svaki Moodle VM
resource "azurerm_managed_disk" "moodle_data_disk" {
  for_each = {
    for pair in flatten([
      for dev in local.developers : [
        for i in range(2) : {
          key = "${dev.ime}-${dev.prezime}-moodle${i + 1}"
          dev = dev
        }
      ]
    ]) : pair.key => pair
  }

  name                = "disk-${each.key}-testing"
  location            = var.location
  resource_group_name = azurerm_resource_group.developer_rg["${each.value.dev.ime}-${each.value.dev.prezime}"].name
  storage_account_type = "Standard_LRS"
  create_option       = "Empty"
  disk_size_gb        = 32

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Attach data disk na Moodle VM
resource "azurerm_virtual_machine_data_disk_attachment" "moodle_disk_attach" {
  for_each = {
    for pair in flatten([
      for dev in local.developers : [
        for i in range(2) : {
          key = "${dev.ime}-${dev.prezime}-moodle${i + 1}"
          dev = dev
        }
      ]
    ]) : pair.key => pair
  }

  managed_disk_id    = azurerm_managed_disk.moodle_data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.moodle_vm[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}