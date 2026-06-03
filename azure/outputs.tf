output "jumphost_public_ips" {
  description = "Javne IP adrese Jump Hostova"
  value = {
    for dev in local.developers :
    "${dev.ime}-${dev.prezime}" => azurerm_public_ip.jumphost_pip["${dev.ime}-${dev.prezime}"].ip_address
  }
}

output "moodle_private_ips" {
  description = "Privatne IP adrese Moodle VM-ova"
  value = {
    for key, nic in azurerm_network_interface.moodle_nic :
    key => nic.private_ip_address
  }
}

output "storage_account_names" {
  description = "Imena Storage Accounta"
  value = {
    for key, sa in azurerm_storage_account.dev_storage :
    key => sa.name
  }
}