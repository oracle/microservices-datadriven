resource "random_password" "password" {
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

resource "oci_database_autonomous_database_wallet" "database_wallet" {
  autonomous_database_id = var.autonomous_database_id
  password               = random_password.password.result
  base64_encode_content  = "true"
}

resource "local_file" "database_wallet_file" {
  content_base64 = oci_database_autonomous_database_wallet.database_wallet.content
  filename       = "../wallet/adb_wallet.zip"
}
