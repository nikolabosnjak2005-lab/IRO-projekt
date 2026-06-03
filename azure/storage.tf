# Storage Account za svakog developera (Blob + Files)
resource "azurerm_storage_account" "dev_storage" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                     = "st${replace(each.key, "-", "")}testing"
  resource_group_name      = azurerm_resource_group.developer_rg[each.key].name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Blob container (objektna pohrana) za svakog developera
resource "azurerm_storage_container" "dev_blob" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                  = "moodle-files-${each.key}"
  storage_account_name  = azurerm_storage_account.dev_storage[each.key].name
  container_access_type = "private"
}

# File Share (datotečna pohrana) za svakog developera
resource "azurerm_storage_share" "dev_fileshare" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                 = "backup-${each.key}"
  storage_account_name = azurerm_storage_account.dev_storage[each.key].name
  quota                = 50
}