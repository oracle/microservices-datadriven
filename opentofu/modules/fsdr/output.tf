# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

output "protection_group_ids" {
  description = "Protection group OCIDs by region."
  value = {
    (var.region_0) = module.fsdr_region_0.dr_protection_group_id
    (var.region_1) = module.fsdr_region_1.dr_protection_group_id
  }
}

output "plan_ids" {
  value = module.fsdr_region_1.dr_plan_ids
}

output "plan_execution_ids" {
  value = module.fsdr_region_1.dr_plan_execution_ids
}

output "automatic_dr_configuration_id" {
  value = module.fsdr_region_1.automatic_dr_configuration_id
}

output "regions" {
  description = "Regional protection groups, plans and operations."
  sensitive   = true
  value = {
    region_0 = module.fsdr_region_0
    region_1 = module.fsdr_region_1
  }
}

output "recovery_config" {
  description = "Native preparation configuration written to cfgmgt/stage/fsdr/config.json."
  value       = local.fsdr_recovery_config
}

output "iam_policy_statements" {
  description = "Protection-group and runtime-container IAM statements."
  value = {
    groups     = oci_identity_policy.fsdr.statements
    containers = oci_identity_policy.fsdr_container.statements
  }
}
