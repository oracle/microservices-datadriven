# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

data "oci_disaster_recovery_dr_protection_groups" "region_0" {
  compartment_id = var.compartment_id
  display_name   = format("%s-pg-%s", var.label_prefix, var.region_0)
}

data "oci_disaster_recovery_dr_protection_groups" "region_1" {
  compartment_id = var.compartment_id
  display_name   = format("%s-pg-%s", var.label_prefix, var.region_1)
  provider       = oci.fsdr_region_1
}

data "oci_disaster_recovery_dr_plan_executions" "region_0" {
  count                  = local.groups[var.region_0] == null ? 0 : 1
  dr_protection_group_id = local.groups[var.region_0].id
}

data "oci_disaster_recovery_dr_plan_executions" "region_1" {
  count                  = local.groups[var.region_1] == null ? 0 : 1
  dr_protection_group_id = local.groups[var.region_1].id
  provider               = oci.fsdr_region_1
}
