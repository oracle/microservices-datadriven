locals {
  app_password = var.generate_app_db_passwords ? random_string.grabdish_application_password.result : var.grabdish_application_password
}
output "compute_instance_public_ip" {
  value = module.compute.instance.public_ip
}

output "compartment_id" {
  value = var.compartment_ocid
}

output "generated_instance_ssh_private_key" {
  value = var.generate_ssh_key_pair ? module.compute.instance_keys.private_key_pem : ""
}

output "dbaas_public_ip" {
  value = module.compute.dbaas_public_ip
}

output "dbaas_private_ip" {
  value = module.compute.dbaas_private_ip
}

output "FQDN_database_SN" {
  value =  module.network.subnet
}

output "dbaas_FQDN" {
  value =  join(".", [module.compute.dbaas_display_name,module.network.subnet_domain_name])
}

output "Database_Password"{
  value = var.generate_app_db_passwords ? random_string.grabdish_database_password.result : var.grabdish_database_password
}

output "Grabdish_Application_Password"{
  value = local.app_password
}

output "Login_Instructions" {
  #type = URL
  value = "Login to http://${module.compute.instance.public_ip} using username: grabdish password: ${local.app_password} "
}

/*
output "dbaas_password"{
  value = var.grabdish_database_password
}

output "app_password"{
  value = var.grabdish_application_password
}
*/
/*
output "Database_Password"{
  value = module.compute.Grabdish_Application_Password
}

output "Grabdish_Application_Password"{
  value = module.compute.On_Premise_Database_Password
}

*/