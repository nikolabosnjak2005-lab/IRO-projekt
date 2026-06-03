data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "developer_assignment" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  scope                = azurerm_resource_group.developer_rg[each.key].id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = "3a0c6288-9786-4937-bbdd-719117430cbc"
}

resource "azurerm_role_assignment" "lead_assignment" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = "3a0c6288-9786-4937-bbdd-719117430cbc"

  lifecycle {
    ignore_changes = all
  }
}