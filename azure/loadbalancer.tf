# Load Balancer za svakog developera
resource "azurerm_lb" "dev_lb" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                = "lb-techsprint-${each.key}-testing"
  location            = var.location
  resource_group_name = azurerm_resource_group.developer_rg[each.key].name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "frontend"
    subnet_id                     = azurerm_subnet.dev_subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project     = var.project_tag
    environment = var.environment_tag
  }
}

# Backend pool
resource "azurerm_lb_backend_address_pool" "dev_lb_pool" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name            = "backend-pool-${each.key}"
  loadbalancer_id = azurerm_lb.dev_lb[each.key].id
}

# Health probe
resource "azurerm_lb_probe" "dev_lb_probe" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name            = "http-probe-${each.key}"
  loadbalancer_id = azurerm_lb.dev_lb[each.key].id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# Load balancing pravilo
resource "azurerm_lb_rule" "dev_lb_rule" {
  for_each = { for dev in local.developers : "${dev.ime}-${dev.prezime}" => dev }

  name                           = "http-rule-${each.key}"
  loadbalancer_id                = azurerm_lb.dev_lb[each.key].id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dev_lb_pool[each.key].id]
  probe_id                       = azurerm_lb_probe.dev_lb_probe[each.key].id
}