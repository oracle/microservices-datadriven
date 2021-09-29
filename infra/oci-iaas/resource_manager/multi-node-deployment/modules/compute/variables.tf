variable "tenancy_ocid" {}
variable "region" {}

variable "target_compartment_id" {
  description = "OCID of the compartment where the compute is being created"
  type        = string
}

variable "vcn_id" {
  description = "VCN OCID where the instance is going to be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID where the instance is going to be created"
  type        = string
}

variable "image_os" {
  default = "Oracle Linux"
}

variable "image_os_version" {
  default = "8"
}

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
  type        = string
}

variable "use_tenancy_level_policy" {
  description = "Compute instance to access all resources at tenancy level"
  type        = bool
}

variable "common_tags" {
  description = "Tags"
  type        = map(string)
}

variable "generate_app_db_passwords" {
  description = "Auto-generate Grabdish Application and Database Passwords"
  type = string
}

variable "grabdish_database_password" {
  description = "grabdish_database_password"
  type        = string
}

variable "grabdish_application_password" {
  description = "grabdish_application_password"
  type        = string
}

/*
variable "iaas_public_repo" {
  description = "Repository URI to execute post provisioning infrastructure setup scripts"
  type        = string
  #default = ""
}

variable "app_public_repo" {
  description = "Repository URI to execute post provisioning Application setup scripts"
  type        = string
  #default = ""
}
*/
variable "dbaas_FQDN" {
  description = "dbaas_FQDN"
  type        = string
}


variable "iaas_app_public_repo" {
  description = "Repository URI to execute infrastructure and application setup scripts"
  type        = string
  default     = "git clone -b main  --single-branch https://github.com/vishalmmehra/microservices-datadriven"
  #default = ""
}

