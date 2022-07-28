# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

// Basic Hidden
variable "tenancy_ocid" {}
variable "compartment_ocid" {
  default = ""
}
variable "region" {}

// Extra Hidden

variable "user_ocid" {
  default = ""
}

// General Configuration
variable "proj_abrv" {
  default = "dcms"
}
variable "size" {
    default = "XS"
}
variable "adb_license_model" {
  default = "BRING_YOUR_OWN_LICENSE"
}
// Block APEX/ORDS Dev and Admin Tools 
// variable "enable_lbaas_ruleset" {
//  default = "false"
// }

// Bastion
variable "create_bastion_session" {
  default = true
}

# Software versions for ORDS server
variable "sotfware_ver" {
  type = map(any)
  default = {
    "jdk-17" = "2000:17.0.4-ga.x86_64"
//    "ords"   = "22.2.1-2.el7"
    "ords"   = "22.2.0-6.el7"
    "sqlcl"  = "22.2.0-2.el7"
  }
}

//The sizing is catering for schema.yaml visibility
//Default is ALF (size) though this boolean is false
//Check the locals at bottom for logic
variable "always_free" {
  default = "false"
}

variable "adb_cpu_core_count" {
  type = map
  default = {
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "XS"  = 1
    "ALF" = 1
  }
}

variable "adb_dataguard" {
  type = map
  default = {
    "L"   = true
    "M"   = true
    "S"   = false
    "XS"  = false
    "ALF" = false
  }
}

variable "flex_lb_min_shape" {
  type = map
  default = {
    "L"   = 100
    "M"   = 100
    "S"   = 10
    "XS"  = 10
    "ALF" = 10
  }
}

variable "flex_lb_max_shape" {
  type = map
  default = {
    "L"   = 1250
    "M"   = 1250
    "S"   = 480
    "XS"  = 10
    "ALF" = 10
  }
}

// Number of ORDS Servers; Scalable x3 (excl. XS/ALF)
variable "compute_instances" {
  type = map
  default = {
    "L"   = 3
    "M"   = 2
    "S"   = 1
    "XS"  = 1
    "ALF" = 1
  }
}

// Scalable x2 (excl. XS/ALF)
variable "compute_flex_shape_ocpus" {
  type = map
  default = {
    "L"   = 4
    "M"   = 2
    "S"   = 1
    "XS"  = 1
    "ALF" = 1
  }
}

variable "adb_storage_size_in_tbs" {
  default = 1
}

variable "adb_db_version" {
  type = map
  default = {
    "L"   = "19c"
    "M"   = "19c"
    "S"   = "19c"
    "XS"  = "19c"
    "ALF" = "21c"
  }
}

variable "linux_os_version" {
  default = "7.9"
}

variable "bastion_user" {
  default = "opc"
}

// VCN Configurations Variables
variable "vcn_cidr" {
  default = "172.16.0.0/24"
}

variable "vcn_is_ipv6enabled" {
  default = true
}

variable "public_subnet_cidr" {
  default = "172.16.0.0/25"
}

variable "private_subnet_cidr" {
  default = "172.16.0.128/25"
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
  sizing               = var.always_free ? "ALF" : var.size
  is_paid              = local.sizing != "ALF" ? true : false
  is_scalable          = local.sizing != "ALF" && local.sizing != "XS" ? true : false
  adb_private_endpoint = local.sizing != "ALF" ? true  : false
  compute_image        = local.sizing != "ALF" ? "Oracle Autonomous Linux" : "Oracle Linux"
  compute_shape        = local.sizing != "ALF" ? "VM.Standard.E4.Flex" : "VM.Standard.E2.1.Micro"
  is_flexible_shape    = contains(local.compute_flexible_shapes, local.compute_shape)
  compartment_ocid     = var.compartment_ocid != "" ? var.compartment_ocid : var.tenancy_ocid
  bastion_ssh          = var.create_bastion_session ? replace(replace(oci_bastion_session.session_managed_ssh[0].ssh_metadata.command, "<privateKey>","${path.module}/bastion_key"),"\"","'") : "Bastion Disabled"
  bastion_tunnel       = var.create_bastion_session ? replace(replace(replace(oci_bastion_session.session_forward_ssh[0].ssh_metadata.command, "<privateKey>", "${path.module}/bastion_key -v"), "\"", "'"),"<localPort>", 1521) : "Bastion Disabled"
}