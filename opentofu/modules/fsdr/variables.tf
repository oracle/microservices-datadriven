# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

variable "tenancy_id" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "label_prefix" {
  type = string
}

variable "region_0" {
  description = "Initial primary region."
  type        = string
}

variable "region_1" {
  description = "Initial standby region."
  type        = string
}

variable "objectstorage_namespace" {
  type = string
}

variable "clusters" {
  description = "Regional infrastructure and generated Kubernetes configuration paths."
  type = map(object({
    cluster_id    = string
    workers_group = string
    database_id   = string
    node_pools    = map(string)
    files = object({
      kubeconfig = string
      manifest   = string
      prereqs    = string
      app        = string
    })
    private_endpoint    = string
    subnet_id           = string
    availability_domain = string
    lb_id               = string
    lb_ip               = string
  }))
}

variable "external_databases" {
  description = "Existing database OCIDs mapped to their owning compartments."
  type        = map(string)
  default     = {}
}

variable "namespaces" {
  description = "Application namespaces protected by OKE backups."
  type        = list(string)
}

variable "use_local_charts" {
  type    = bool
  default = false
}

variable "node_counts" {
  type = object({ cpu = number, gpu = number })
}

variable "standby_node_counts" {
  type = object({ cpu = number, gpu = number })
}

variable "backup_schedule" {
  type    = string
  default = "FREQ=HOURLY;INTERVAL=1"
}

variable "backup_retention" {
  type    = number
  default = 24
}

variable "disassociate_trigger" {
  type    = number
  default = null
}

variable "plan_types" {
  type    = set(string)
  default = ["SWITCHOVER", "FAILOVER"]
  validation {
    condition     = alltrue([for plan_type in var.plan_types : contains(["SWITCHOVER", "FAILOVER", "START_DRILL", "STOP_DRILL"], plan_type)])
    error_message = "DR plan types must be SWITCHOVER, FAILOVER, START_DRILL, or STOP_DRILL."
  }
}

variable "plan_refresh_trigger" {
  type    = number
  default = null
}

variable "plan_verify_trigger" {
  type    = number
  default = null
}

variable "timeouts" {
  type = object({
    create = optional(string, "20m")
    update = optional(string, "20m")
    delete = optional(string, "20m")
  })
  default = {}
}

variable "executions" {
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
}

variable "automatic_dr" {
  type = object({
    is_auto_switchover_enabled = optional(bool, false)
    is_auto_failover_enabled   = optional(bool, false)
  })
  default = null
}
