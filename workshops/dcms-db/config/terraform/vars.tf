# Copyright © 2020, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

// Basic Hidden
variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "region" {}
variable "db_name" {}

// Extra Hidden
variable "user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}

variable "ssh_public_key_file" {
  default = ""
}

variable "ssh_private_key_file" {
  default = ""
}

// General Configuration
variable "proj_abrv" {
  default = "apexpoc"
}
variable "size" {
    default = "ALF"
}

variable "adb_license_model" {
  default = "BRING_YOUR_OWN_LICENSE"
}

variable "adb_cpu_core_count" {
  type = map
  default = {
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "ALF" = 1
  }
}

variable "adb_dataguard" {
  type = map
  default = {
    "L"   = true
    "M"   = true
    "S"   = false
    "ALF" = false
  }
}

variable "flex_lb_min_shape" {
  type = map
  default = {
    "L"   = 100
    "M"   = 100
    "S"   = 10
    "ALF" = 10
  }
}

variable "flex_lb_max_shape" {
  type = map
  default = {
    "L"   = 1250
    "M"   = 1250
    "S"   = 480
    "ALF" = 10
  }
}

// Number of ORDS Servers; Scalable x3 (excl. ALF)
variable "compute_instances" {
  type = map
  default = {
    "L"   = 3
    "M"   = 2
    "S"   = 1
    "ALF" = 1
  }
}

// Scalable x2 (excl. ALF)
variable "compute_flex_shape_ocpus" {
  type = map
  default = {
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "ALF" = 1
  }
}

variable "adb_storage_size_in_tbs" {
  default = 1
}

variable "adb_db_version" {
  default = "21c"
}

variable "compute_os" {
  default = "Oracle Linux"
}

variable "linux_os_version" {
  default = "8"
}

variable "bastion_user" {
  default = "opc"
}

// VCN Configurations Variables
variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "vcn_is_ipv6enabled" {
  default = false
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Standard.A1.Flex",
    "VM.Optimized3.Flex"
  ]
}

# Dynamic Vars
locals {
  is_always_free       = var.size != "ALF" ? false : true
  adb_private_endpoint = var.size != "ALF" ? true  : false
#  compute_shape        = var.size != "ALF" ? "VM.Standard.E3.Flex" : "VM.Standard.E2.1.Micro"
  compute_shape        = var.size != "ALF" ? "VM.Standard.E3.Flex" : "VM.Standard.E3.Flex"
  is_flexible_shape    = contains(local.compute_flexible_shapes, local.compute_shape)
}
