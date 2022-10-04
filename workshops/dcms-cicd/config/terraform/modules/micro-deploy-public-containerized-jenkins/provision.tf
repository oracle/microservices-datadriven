resource "null_resource" "upload_wallet" {
  provisioner "file" {
    connection {
      type        = "ssh"
      agent       = false
      user        = opc
      host        = oci_core_public_ip.jenkins_public_ip.ip_address
      private_key = tls_private_key.tls_key_pair.private_key_pem
    }
    source = local_file.database_wallet_file.filename
    # Place in an existing directory; cloud-init will move it
    destination = "/home/opc/wallet/adb_wallet.zip"
  }
}
