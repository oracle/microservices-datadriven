//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "random_password" "database_admin_password" {
  length  = 12
  upper   = true
  lower   = true
  numeric  = true
  special = false
  min_lower = "1"
  min_upper = "1"
  min_numeric = "1"
}

resource "oci_database_autonomous_database" "autonomous_database" {
  #Required
  admin_password           = random_password.database_admin_password.result
  compartment_id           = var.ociCompartmentOcid
  cpu_core_count           = "1"
  data_storage_size_in_tbs = "1"
  db_name                  = var.dbName
  is_free_tier             = var.dbIsFreeTier
  db_version               = var.dbVersion
  db_workload              = "OLTP"
  display_name             = var.displayName
  is_auto_scaling_enabled  = "false"
  is_preview_version_with_service_terms_accepted = "false"
}

output "db_ocid" {
  value = oci_database_autonomous_database.autonomous_database.id
}
