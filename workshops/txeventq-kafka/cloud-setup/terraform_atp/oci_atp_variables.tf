// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

variable "tenancy_ocid" { }
variable "user_ocid" { }
variable "region" { }
variable "compartment_ocid" { }

variable "autonomous_database_db_workload" {
  default = "OLTP"
}

variable "autonomous_database_defined_tags_value" {
  default = "value"
}

variable "autonomous_database_license_model" {
#  default = "BRING_YOUR_OWN_LICENSE"
  default = "LICENSE_INCLUDED"
}

variable "autonomous_database_is_dedicated" {
  default = false
}

variable "autonomous_database_cpu_core_count" {
  default = "1"
}

variable "autonomous_database_db_name" {
  default = "atp_db1"
}

variable "autonomous_database_db_version" {
  description = "Oracle Autonomous Database Version"
  type = string
  default = "19c"
  validation {
    condition     = contains(["19c", "21c"], var.autonomous_database_db_version)
    error_message = "Valid values for var: autonomous_database_db_version are (19c, 21c)."
  }
}

variable "autonomous_database_display_name" {
  default = "MyATPDB"
}

variable "autonomous_database_data_storage_size_in_tbs" {
  default = "1"
}

variable "autonomous_database_is_free_tier" {
  default = false
}