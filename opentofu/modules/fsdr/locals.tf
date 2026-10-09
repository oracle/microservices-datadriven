# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

locals {
  plan_types = { for plan_type in var.plan_types : lower(plan_type) => plan_type }
  backup_buckets = {
    (var.region_0) = oci_objectstorage_bucket.fsdr_backup_primary.name
    (var.region_1) = oci_objectstorage_bucket.fsdr_backup_standby.name
  }
  fsdr_clusters = { for region, cluster in var.clusters : region => merge(cluster, {
    backup_bucket = local.backup_buckets[region]
  }) }
  fsdr_recovery_config = {
    label               = var.label_prefix
    namespace           = var.objectstorage_namespace
    clusters            = local.fsdr_clusters
    namespaces          = var.namespaces
    use_local_charts    = var.use_local_charts
    compartment_id      = var.compartment_id
    node_counts         = var.node_counts
    standby_node_counts = var.standby_node_counts
    plan_types          = var.plan_types
    backup_schedule     = var.backup_schedule
    backup_retention    = var.backup_retention
    groups = {
      (var.region_0) = module.fsdr_region_0.dr_protection_group_id
      (var.region_1) = module.fsdr_region_1.dr_protection_group_id
    }
  }
}
