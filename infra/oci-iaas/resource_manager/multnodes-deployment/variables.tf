variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}

/*
resource  "random_password" "onprem_dbaas_password" {
  length           = 12
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}

resource "random_password" "onprem_application_password" {
  length           = 12
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}
*/


variable "instance_shape" {
  description = "Shape of the instance"
  type        = string
}

variable "generate_ssh_key_pair" {
  description = "Auto-generate SSH key pair"
  type        = string
}

variable "ssh_public_key" {
  description = "ssh public key used to connect to the compute instance"
  default     = "" # This value has to be defaulted to blank, otherwise terraform apply would request for one.
  type        = string
}

variable "use_tenancy_level_policy" {
  description = "Compute instance to access all resources at tenancy level"
  type        = bool
}

variable "generate_app_db_passwords" {
  description = "Automatically generate Grabdish Application and Database Passwords"
  type        = string
}

variable "grabdish_database_password" {
  description = "grabdish_database_password"
  type        = string
  default = "OraDB4U13579"

}

variable "grabdish_application_password" {
  description = "grabdish_application_password"
  type        = string
  default = "Welcome12345"

}

variable "iaas_public_repo" {
  description = "Repository URI to execute post provisioning infrastructure setup scripts"
  type        = string
  default     = "git clone -b master  --single-branch https://github.com/vishalmmehra/microservices-datadriven-infra/"
 #default = ""
}

variable "app_public_repo" {
  description = "Repository URI to execute post provisioning Application setup scripts"
  type        = string
  default     = "git clone -b 21.6.1 --single-branch https://github.com/oracle/microservices-datadriven.git"
  #default = ""
}



