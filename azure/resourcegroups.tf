resource "azurerm_resource_group" "developer_rg" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name     = "rg-techsprint-${each.key}-testing"
  location = var.location

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

resource "azurerm_resource_group" "lead_rg" {
  name     = "rg-techsprint-devops-lead-testing"
  location = var.location

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}