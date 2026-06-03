locals {
  csv_data = csvdecode(file(var.csv_path))
  
  developers = [
    for user in local.csv_data : user
    if user.rola == "developer"
  ]
  
  devops_lead = [
    for user in local.csv_data : user
    if user.rola == "devops_lead"
  ]
}