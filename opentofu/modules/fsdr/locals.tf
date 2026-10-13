# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

locals {
  plan_types = { for plan_type in var.plan_types : lower(plan_type) => plan_type }
  backup_buckets = {
    (var.region_0) = oci_objectstorage_bucket.fsdr_backup_primary.name
    (var.region_1) = oci_objectstorage_bucket.fsdr_backup_standby.name
  }
  group_summaries = { for region, discovery in {
    (var.region_0) = data.oci_disaster_recovery_dr_protection_groups.region_0.dr_protection_group_collection
    (var.region_1) = data.oci_disaster_recovery_dr_protection_groups.region_1.dr_protection_group_collection
    } : region => try(one([
      for group in discovery[0].items : group if contains(["ACTIVE", "INACTIVE"], group.state)
  ]), null) }
  groups = {
    (var.region_0) = one(data.oci_disaster_recovery_dr_protection_group.region_0[*])
    (var.region_1) = one(data.oci_disaster_recovery_dr_protection_group.region_1[*])
  }
  roles = {
    (var.region_0) = try(local.groups[var.region_0].role, "PRIMARY")
    (var.region_1) = try(local.groups[var.region_1].role, "STANDBY")
  }
  members = { for region, cluster in var.clusters : region => concat([
    {
      member_id                                      = cluster.database_id
      member_type                                    = "AUTONOMOUS_DATABASE"
      autonomous_database_standby_type_for_dr_drills = var.adb_drill_standby_type
    },
    {
      member_id       = cluster.cluster_id
      member_type     = "OKE_CLUSTER"
      peer_cluster_id = var.clusters[region == var.region_0 ? var.region_1 : var.region_0].cluster_id
      backup_location = { bucket = local.backup_buckets[region], namespace = var.objectstorage_namespace }
      backup_config = local.roles[region] == "PRIMARY" ? {
        namespaces                     = concat(var.namespaces, ["obaas-system"])
        backup_schedule                = var.backup_schedule
        replicate_images               = "ENABLE"
        max_number_of_backups_retained = var.backup_retention
      } : null
      managed_node_pool_configs = [for kind, id in cluster.node_pools : {
        id = id, minimum = var.standby_node_counts[kind], maximum = var.node_counts[kind]
      }]
      load_balancer_mappings = [{
        source_load_balancer_id      = cluster.lb_id
        destination_load_balancer_id = var.clusters[region == var.region_0 ? var.region_1 : var.region_0].lb_id
      }]
    }
    ],
    # FSDR updates storage IDs and replication direction during role transitions.
    [for member in module.storage.members : member if local.roles[var.region_0] == "PRIMARY" && region == var.region_0], [
      for member in try(local.groups[region].members, []) : member
      if local.roles[var.region_0] != "PRIMARY" && contains(["VOLUME_GROUP", "FILE_SYSTEM"], member.member_type)
  ]) }
  plans = { for region in [var.region_0, var.region_1] : region => {
    for key, plan_type in local.plan_types : key => {
      display_name    = format("%s-%s-%s", var.label_prefix, key, region)
      type            = plan_type
      refresh_trigger = var.plan_refresh_trigger
      verify_trigger  = var.plan_verify_trigger
      timeouts_create = var.timeouts.create
      timeouts_update = var.timeouts.update
      timeouts_delete = var.timeouts.delete
      } if !var.init_destroy && local.roles[region] == "STANDBY" && (
      plan_type != "STOP_DRILL" || try(local.groups[region].state == "INACTIVE" && local.groups[region].lifecycle_sub_state == "DR_DRILL_IN_PROGRESS", false)
    )
  } }
  automatic_dr = { for region, cluster in var.clusters : region => var.init_destroy || var.automatic_dr == null || local.roles[region] != "STANDBY" ? null : {
    display_name = format("%s-automatic-%s", var.label_prefix, region)
    members = [{
      member_id                  = cluster.database_id
      member_type                = "AUTONOMOUS_DATABASE"
      is_auto_switchover_enabled = var.automatic_dr.is_auto_switchover_enabled
      is_auto_failover_enabled   = var.automatic_dr.is_auto_failover_enabled
    }]
  } }
}
