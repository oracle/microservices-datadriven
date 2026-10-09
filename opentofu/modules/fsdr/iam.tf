# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

resource "oci_identity_dynamic_group" "fsdr" {
  compartment_id = var.tenancy_id
  name           = "${var.label_prefix}-groups"
  description    = "OBaaS FSDR protection groups"
  matching_rule  = "Any {resource.id = '${module.fsdr_region_0.dr_protection_group_id}', resource.id = '${module.fsdr_region_1.dr_protection_group_id}'}"
  provider       = oci.home_region
}

resource "oci_identity_policy" "fsdr" {
  compartment_id = var.tenancy_id
  name           = "${var.label_prefix}-groups"
  description    = "OBaaS full-stack recovery"
  statements = concat([for family in ["disaster-recovery-family", "autonomous-database-family", "cluster-family", "instance-family", "compute-container-family", "object-family", "volume-family", "file-family", "virtual-network-family", "load-balancers", "repos"] :
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr.name} to manage ${family} in compartment id ${var.compartment_id}"
    ], [
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr.name} to read objectstorage-namespaces in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr.name} to read all-resources in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr.name} to use instance-images in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr.name} to use tag-namespaces in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr.name} to read repos in tenancy"
    ], flatten([for cluster in values(local.fsdr_clusters) : [for service_account in ["brie-creator", "brie-reader"] :
      "Allow any-user to manage objects in compartment id ${var.compartment_id} where all {request.principal.type = 'workload', request.principal.namespace = 'brie', request.principal.service_account = '${service_account}', request.principal.cluster_id = '${cluster.cluster_id}'}"
      ]]), flatten([for cluster in values(local.fsdr_clusters) : [for family in ["object-family", "cluster-family"] :
      "Allow dynamic-group ${cluster.workers_group} to manage ${family} in compartment id ${var.compartment_id}"
    ]]), [for database_id, compartment_id in var.external_databases :
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr.name} to manage autonomous-databases in compartment id ${compartment_id} where target.database.id = '${database_id}'"
  ])
  provider = oci.home_region
}

resource "oci_identity_dynamic_group" "fsdr_container" {
  compartment_id = var.tenancy_id
  name           = "${var.label_prefix}-containers"
  description    = "FSDR runtime OKE container instances"
  matching_rule  = "ALL {resource.type = 'computecontainerinstance', resource.compartment.id = '${var.compartment_id}'}"
  provider       = oci.home_region
}

resource "oci_identity_policy" "fsdr_container" {
  compartment_id = var.tenancy_id
  name           = "${var.label_prefix}-containers"
  description    = "FSDR runtime OKE operations"
  statements = [for family in ["object-family", "cluster-family"] :
    "Allow dynamic-group ${oci_identity_dynamic_group.fsdr_container.name} to manage ${family} in compartment id ${var.compartment_id}"
  ]
  provider = oci.home_region
}
