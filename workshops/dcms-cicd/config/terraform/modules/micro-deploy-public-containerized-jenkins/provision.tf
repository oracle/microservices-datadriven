resource "null_resource" "jenkins_provisioner" {
  depends_on = [oci_core_instance.jenkins_vm, oci_core_public_ip.jenkins_public_ip]

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = oci_core_public_ip.jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

    }
    inline = [
      "while [ ! -f /tmp/cloud-init-complete ]; do sleep 1; done",
      "docker-compose -f /home/opc/jenkins.yaml up -d"
    ]
  }
}

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
