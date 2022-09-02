//================= create ATP Instance =======================================
resource "random_string" "autonomous_database_wallet_password" {
  length  = 16
  special = true
}
resource "random_password" "database_admin_password" {
  length  = 12
  upper   = true
  lower   = true
  numeric = true
  special = false
  min_lower = "1"
  min_upper = "1"
  min_numeric = "1"
}
resource "oci_database_autonomous_database" "autonomous_database_atp" {
  #Required
  compartment_id           = var.compartment_ocid
  db_name                  = var.autonomous_database_db_name

  #Optional
  admin_password           = random_password.database_admin_password.result
  cpu_core_count           = var.autonomous_database_cpu_core_count
  data_storage_size_in_tbs = var.autonomous_database_data_storage_size_in_tbs
  # is_free_tier = true , if there exists sufficient service limit
  is_free_tier             = var.autonomous_database_is_free_tier
  db_workload              = var.autonomous_database_db_workload
  db_version               = var.autonomous_database_db_version
  license_model            = var.autonomous_database_license_model
  display_name             = var.autonomous_database_display_name
  is_auto_scaling_enabled                        = "false"
  is_preview_version_with_service_terms_accepted = "false"
}


