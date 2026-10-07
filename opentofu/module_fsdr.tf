# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

variable "fsdr_enabled" {
  description = "Create FSDR protection groups and standby-region plans."
  type        = bool
  default     = false
}

variable "fsdr_region_1" {
  description = "Subscribed OCI standby region, distinct from region."
  type        = string
  default     = ""
}

variable "fsdr_disassociate_trigger" {
  description = "Increment to disassociate the protection groups."
  type        = number
  default     = 0
}

variable "fsdr_plan_types" {
  description = "Standby-region plan types to create."
  type        = set(string)
  default     = ["SWITCHOVER", "FAILOVER"]
  validation {
    condition     = alltrue([for plan_type in var.fsdr_plan_types : contains(["SWITCHOVER", "FAILOVER", "START_DRILL", "STOP_DRILL"], plan_type)])
    error_message = "FSDR plan types must be SWITCHOVER, FAILOVER, START_DRILL, or STOP_DRILL."
  }
}

variable "fsdr_plan_refresh_trigger" {
  description = "Increment to refresh generated DR plans after member changes."
  type        = number
  default     = null
}

variable "fsdr_plan_verify_trigger" {
  description = "Increment to verify generated DR plans."
  type        = number
  default     = null
}

variable "fsdr_adb_drill_standby_type" {
  description = "OCI Autonomous Database standby mechanism for DR drills."
  type        = string
  default     = null
}

variable "fsdr_timeouts" {
  description = "Create, update, and delete timeouts for FSDR groups, plans, and Automatic DR configuration."
  type = object({
    create = optional(string, "20m")
    update = optional(string, "20m")
    delete = optional(string, "20m")
  })
  default = {}
}

variable "fsdr_plan_executions" {
  description = "Explicit plan executions keyed by lowercase plan type, such as switchover or start_drill. Apply submits each configured execution."
  type = map(object({
    plan_execution_type   = string
    are_prechecks_enabled = optional(bool, true)
    are_warnings_ignored  = optional(bool, false)
    display_name          = optional(string, null)
    timeouts_create       = optional(string, "20m")
    timeouts_update       = optional(string, "20m")
    timeouts_delete       = optional(string, "20m")
  }))
  default = {}
  validation {
    condition     = length(var.fsdr_plan_executions) <= 1
    error_message = "Submit one FSDR plan execution per apply."
  }
}

variable "fsdr_automatic_dr" {
  description = "Opt-in ADB event-driven DR on the standby protection group. Prepare Resource Principal IAM policies before enabling."
  type = object({
    is_auto_switchover_enabled = optional(bool, false)
    is_auto_failover_enabled   = optional(bool, false)
  })
  default = null
  validation {
    condition     = var.fsdr_automatic_dr == null ? true : var.fsdr_automatic_dr.is_auto_switchover_enabled || var.fsdr_automatic_dr.is_auto_failover_enabled
    error_message = "Automatic DR requires at least one enabled switchover or failover event."
  }
}

resource "terraform_data" "fsdr_validation" {
  count = var.fsdr_enabled || var.fsdr_automatic_dr != null || length(var.fsdr_plan_executions) > 0 ? 1 : 0
  lifecycle {
    precondition {
      condition     = var.fsdr_enabled && trimspace(var.fsdr_region_1) != "" && var.fsdr_region_1 != var.region
      error_message = "Enable FSDR and select a non-empty standby region distinct from region."
    }
    precondition {
      condition     = var.fsdr_automatic_dr == null || local.fsdr_include_adb
      error_message = "Automatic DR requires an Autonomous Database protected by FSDR."
    }
    precondition {
      condition = var.fsdr_automatic_dr == null ? true : (
        (!var.fsdr_automatic_dr.is_auto_switchover_enabled || contains(var.fsdr_plan_types, "SWITCHOVER")) &&
        (!var.fsdr_automatic_dr.is_auto_failover_enabled || contains(var.fsdr_plan_types, "FAILOVER"))
      )
      error_message = "Automatic DR requires the plan type for every enabled event."
    }
    precondition {
      condition     = alltrue([for key in keys(var.fsdr_plan_executions) : contains(keys(local.fsdr_plan_types), key)])
      error_message = "Each execution must reference a configured lowercase FSDR plan type."
    }
  }
}

// DR Log Buckets (one per region — each protection group needs a bucket in its own region)
resource "oci_objectstorage_bucket" "fsdr_logs_region_1" {
  for_each       = var.fsdr_enabled ? { fsdr_region_1 = true } : {}
  compartment_id = local.compartment_ocid
  name           = format("%s-logs-%s", local.fsdr_label_prefix, var.fsdr_region_1)
  namespace      = data.oci_objectstorage_namespace.objectstorage_namespace.namespace
  provider       = oci.fsdr_region_1
  depends_on     = [terraform_data.fsdr_validation]
}

resource "oci_objectstorage_bucket" "fsdr_logs_region_0" {
  for_each       = var.fsdr_enabled ? { fsdr_region_0 = true } : {}
  compartment_id = local.compartment_ocid
  name           = format("%s-logs-%s", local.fsdr_label_prefix, var.region)
  namespace      = data.oci_objectstorage_namespace.objectstorage_namespace.namespace
  depends_on     = [terraform_data.fsdr_validation]
}

// Cross-Region ADB Standby (Autonomous Data Guard — required before FSDR can manage ADB failover)
resource "oci_database_autonomous_database" "dr_adb_standby" {
  for_each                      = local.fsdr_include_adb ? { fsdr_region_1 = true } : {}
  compartment_id                = local.compartment_ocid
  source                        = "CROSS_REGION_DISASTER_RECOVERY"
  source_id                     = local.db_ocid
  db_name                       = local.db_name
  display_name                  = format("%s", local.fsdr_label_prefix)
  remote_disaster_recovery_type = "ADG"
  lifecycle {
    ignore_changes = [whitelisted_ips]
  }
  provider   = oci.fsdr_region_1
  depends_on = [terraform_data.fsdr_validation]
}

locals {
  fsdr_plan_types = var.fsdr_enabled ? { for plan_type in var.fsdr_plan_types : lower(plan_type) => plan_type } : {}
}

module "fsdr_region_1" {
  for_each            = var.fsdr_enabled ? { fsdr_region_1 = true } : {}
  source              = "./modules/fsdr"
  compartment_id      = local.compartment_ocid
  display_name        = format("%s-pg-%s", local.fsdr_label_prefix, var.fsdr_region_1)
  timeouts            = var.fsdr_timeouts
  plan_association_id = module.fsdr_region_0["fsdr_region_0"].dr_protection_group_id
  log_location = {
    bucket    = oci_objectstorage_bucket.fsdr_logs_region_1["fsdr_region_1"].name
    namespace = oci_objectstorage_bucket.fsdr_logs_region_1["fsdr_region_1"].namespace
  }
  members = local.fsdr_include_adb ? [{
    member_id                                      = oci_database_autonomous_database.dr_adb_standby["fsdr_region_1"].id
    member_type                                    = "AUTONOMOUS_DATABASE"
    autonomous_database_standby_type_for_dr_drills = var.fsdr_adb_drill_standby_type
  }] : []
  plans = { for key, plan_type in local.fsdr_plan_types : key => {
    display_name    = format("%s-%s-%s", local.fsdr_label_prefix, key, var.fsdr_region_1)
    type            = plan_type
    refresh_trigger = var.fsdr_plan_refresh_trigger
    verify_trigger  = var.fsdr_plan_verify_trigger
    timeouts_create = var.fsdr_timeouts.create
    timeouts_update = var.fsdr_timeouts.update
    timeouts_delete = var.fsdr_timeouts.delete
  } }
  executions = var.fsdr_plan_executions
  automatic_dr = local.fsdr_include_adb && var.fsdr_automatic_dr != null ? {
    display_name = format("%s-automatic-%s", local.fsdr_label_prefix, var.fsdr_region_1)
    members = [{
      member_id                  = oci_database_autonomous_database.dr_adb_standby["fsdr_region_1"].id
      member_type                = "AUTONOMOUS_DATABASE"
      is_auto_switchover_enabled = var.fsdr_automatic_dr.is_auto_switchover_enabled
      is_auto_failover_enabled   = var.fsdr_automatic_dr.is_auto_failover_enabled
    }]
  } : null
  providers = {
    oci = oci.fsdr_region_1
  }
}

module "fsdr_region_0" {
  for_each       = var.fsdr_enabled ? { fsdr_region_0 = true } : {}
  source         = "./modules/fsdr"
  compartment_id = local.compartment_ocid
  display_name   = format("%s-pg-%s", local.fsdr_label_prefix, var.region)
  association = {
    role        = "PRIMARY"
    peer_region = var.fsdr_region_1
    peer_id     = module.fsdr_region_1["fsdr_region_1"].dr_protection_group_id
  }
  log_location = {
    bucket    = oci_objectstorage_bucket.fsdr_logs_region_0["fsdr_region_0"].name
    namespace = oci_objectstorage_bucket.fsdr_logs_region_0["fsdr_region_0"].namespace
  }
  members = local.fsdr_include_adb ? [{
    member_id                                      = local.db_ocid
    member_type                                    = "AUTONOMOUS_DATABASE"
    autonomous_database_standby_type_for_dr_drills = var.fsdr_adb_drill_standby_type
  }] : []
  disassociate_trigger = var.fsdr_disassociate_trigger
  timeouts             = var.fsdr_timeouts
}

output "fsdr_protection_group_ids" {
  description = "FSDR protection group OCIDs by region."
  value = var.fsdr_enabled ? {
    (var.region)        = module.fsdr_region_0["fsdr_region_0"].dr_protection_group_id
    (var.fsdr_region_1) = module.fsdr_region_1["fsdr_region_1"].dr_protection_group_id
  } : {}
}

output "fsdr_plan_ids" {
  description = "Standby-region DR plan OCIDs keyed by lowercase plan type."
  value       = try(module.fsdr_region_1["fsdr_region_1"].dr_plan_ids, {})
}

output "fsdr_plan_execution_ids" {
  description = "Explicit DR execution OCIDs keyed by lowercase plan type."
  value       = try(module.fsdr_region_1["fsdr_region_1"].dr_plan_execution_ids, {})
}

output "fsdr_automatic_dr_configuration_id" {
  description = "Standby-region Automatic DR configuration OCID."
  value       = try(module.fsdr_region_1["fsdr_region_1"].automatic_dr_configuration_id, null)
}
