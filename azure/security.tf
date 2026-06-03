# NSG za jump host (samo SSH javno dostupan)
resource "azurerm_network_security_group" "jumphost_nsg" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                = "nsg-jumphost-${each.key}-testing"
  location            = var.location
  resource_group_name = azurerm_resource_group.developer_rg[each.key].name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# NSG za Moodle VM-ove (bez javnog pristupa)
resource "azurerm_network_security_group" "moodle_nsg" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                = "nsg-moodle-${each.key}-testing"
  location            = var.location
  resource_group_name = azurerm_resource_group.developer_rg[each.key].name

  security_rule {
    name                       = "allow-ssh-from-jumphost"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.${index(local.developers, each.value)}.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.${index(local.developers, each.value)}.1.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# NSG za devops lead
resource "azurerm_network_security_group" "lead_nsg" {
  name                = "nsg-devops-lead-testing"
  location            = var.location
  resource_group_name = azurerm_resource_group.lead_rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}