# Copyright © 2020, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "random_password" "autonomous_database_password" {
  length           = 16
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  min_special      = 1
  override_special = "_#"
  keepers = {
    uuid = "uuid()"
  }
}

resource "oci_database_autonomous_database" "autonomous_database" {
  admin_password           = random_password.autonomous_database_password.result
  compartment_id           = var.compartment_ocid
  db_name                  = var.db_name
  cpu_core_count           = var.adb_cpu_core_count[var.size]
  data_storage_size_in_tbs = var.adb_storage_size_in_tbs
  db_version               = var.adb_db_version
  db_workload              = "OLTP"
  display_name             = "DCMSDBWORKSHOP"
  is_free_tier             = local.is_always_free
  is_auto_scaling_enabled  = local.is_always_free ? false : true
  license_model            = local.is_always_free ? "LICENSE_INCLUDED" : var.adb_license_model
  nsg_ids                  = local.adb_private_endpoint ? [oci_core_network_security_group.security_group_adb[0].id] : null
  private_endpoint_label   = local.adb_private_endpoint ? "ADBPrivateEndpoint" : null
  subnet_id                = local.adb_private_endpoint ? oci_core_subnet.subnet_private[0].id : null
  // This should be variabled but there's an issue with creating DG on initial creation
  is_data_guard_enabled    = false
  lifecycle {
    ignore_changes = all
  }
}

resource "oci_database_autonomous_database_wallet" "database_wallet" {
  autonomous_database_id = oci_database_autonomous_database.autonomous_database.id
  password               = random_password.autonomous_database_password.result
  base64_encode_content  = "true"
}

resource "local_file" "database_wallet_file" {
  content_base64 = oci_database_autonomous_database_wallet.database_wallet.content
  filename       = "uploads/adb_wallet.zip"
}
