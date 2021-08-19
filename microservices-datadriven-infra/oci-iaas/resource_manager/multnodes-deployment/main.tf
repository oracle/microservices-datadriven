locals {
  common_tags = {
    Reference = "on-prem-micro-svc"
  }
}

resource "random_string" "grabdish_database_password" {
  length           = 12
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 0
  override_special = "^[A-Za-z][A-Za-z0-9]+$"
}

resource "random_string" "grabdish_application_password" {
  length           = 12
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}

module "network" {
  source                = "./modules/network"
  target_compartment_id = var.compartment_ocid
  common_tags           = local.common_tags
  #display_name_prefix =    var.new_network_prefix
  # dns_label           = var.new_network_prefix
}

module "compute" {
  source                   = "./modules/compute"
  region                   = var.region
  tenancy_ocid             = var.tenancy_ocid
  target_compartment_id    = var.compartment_ocid
  vcn_id                   = module.network.vcn.id
  subnet_id                = module.network.subnet.id
  instance_shape           = var.instance_shape
  generate_ssh_key_pair    = var.generate_ssh_key_pair
  ssh_public_key           = var.ssh_public_key
  generate_app_db_passwords = var.generate_app_db_passwords
  use_tenancy_level_policy = var.use_tenancy_level_policy
  common_tags              = local.common_tags
  grabdish_database_password = var.generate_app_db_passwords ? random_string.grabdish_database_password.result : var.grabdish_database_password
  grabdish_application_password = var.generate_app_db_passwords ? random_string.grabdish_application_password.result : var.grabdish_application_password
  iaas_public_repo = var.iaas_public_repo
  app_public_repo = var.app_public_repo
  dbaas_FQDN = join(".", [module.compute.dbaas_display_name,module.network.subnet_domain_name])
}