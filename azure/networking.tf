# VNet za svakog developera
resource "azurerm_virtual_network" "dev_vnet" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                = "vnet-techsprint-${each.key}-testing"
  address_space       = ["10.${index(local.developers, each.value)}.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.developer_rg[each.key].name

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Subnet za svaki VNet
resource "azurerm_subnet" "dev_subnet" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                 = "subnet-techsprint-${each.key}-testing"
  resource_group_name  = azurerm_resource_group.developer_rg[each.key].name
  virtual_network_name = azurerm_virtual_network.dev_vnet[each.key].name
  address_prefixes     = ["10.${index(local.developers, each.value)}.1.0/24"]
}

# VNet za devops lead
resource "azurerm_virtual_network" "lead_vnet" {
  name                = "vnet-techsprint-devops-lead-testing"
  address_space       = ["10.100.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.lead_rg.name

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Subnet za devops lead
resource "azurerm_subnet" "lead_subnet" {
  name                 = "subnet-techsprint-devops-lead-testing"
  resource_group_name  = azurerm_resource_group.lead_rg.name
  virtual_network_name = azurerm_virtual_network.lead_vnet.name
  address_prefixes     = ["10.100.1.0/24"]
}