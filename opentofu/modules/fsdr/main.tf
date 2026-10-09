# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

module "fsdr_region_1" {
  source              = "./region"
  compartment_id      = var.compartment_id
  display_name        = "${var.label_prefix}-pg-${var.region_1}"
  timeouts            = var.timeouts
  plan_association_id = module.fsdr_region_0.dr_protection_group_id
  members_ready_id    = terraform_data.fsdr_members.id
  log_location = {
    bucket    = oci_objectstorage_bucket.fsdr_logs_region_1.name
    namespace = var.objectstorage_namespace
  }
  plans = { for key, plan_type in local.plan_types : key => {
    display_name    = "${var.label_prefix}-${key}-${var.region_1}"
    type            = plan_type
    refresh_trigger = var.plan_refresh_trigger
    verify_trigger  = var.plan_verify_trigger
    timeouts_create = var.timeouts.create
    timeouts_update = var.timeouts.update
    timeouts_delete = var.timeouts.delete
  } }
  operations_ready_id = terraform_data.fsdr_prepare.id
  executions          = var.executions
  automatic_dr = var.automatic_dr == null ? null : {
    display_name = "${var.label_prefix}-automatic-${var.region_1}"
    members = [{
      member_id                  = var.clusters[var.region_1].database_id
      member_type                = "AUTONOMOUS_DATABASE"
      is_auto_switchover_enabled = var.automatic_dr.is_auto_switchover_enabled
      is_auto_failover_enabled   = var.automatic_dr.is_auto_failover_enabled
    }]
  }
  providers = {
    oci = oci.fsdr_region_1
  }
}

module "fsdr_region_0" {
  source         = "./region"
  compartment_id = var.compartment_id
  display_name   = "${var.label_prefix}-pg-${var.region_0}"
  association = {
    role        = "PRIMARY"
    peer_region = var.region_1
    peer_id     = module.fsdr_region_1.dr_protection_group_id
  }
  log_location = {
    bucket    = oci_objectstorage_bucket.fsdr_logs_region_0.name
    namespace = var.objectstorage_namespace
  }
  disassociate_trigger = var.disassociate_trigger
  timeouts             = var.timeouts
}
