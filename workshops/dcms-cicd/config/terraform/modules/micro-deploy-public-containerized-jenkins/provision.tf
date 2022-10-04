resource "null_resource" "upload_wallet" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "file" {
    connection {
      type        = "ssh"
      agent       = false
      user        = "opc"
      host        = oci_core_public_ip.jenkins_public_ip.ip_address
      private_key = tls_private_key.tls_key_pair.private_key_pem
    }
    source = local_file.database_wallet_file.filename
    # this will be moved by cloud-init and not left in /tmp
    destination = "/tmp/adb_wallet.zip"
  }
}
