data "template_file" "jenkins_docker_compose" {
  template = file("${path.module}/scripts/jenkins.yaml")

  vars = {
    public_key_openssh = tls_private_key.tls_key_pair.public_key_openssh,
    jenkins_user       = var.jenkins_user,
    jenkins_password   = var.jenkins_password
  }
}

resource "null_resource" "jenkins_provisioner" {
  depends_on = [oci_core_instance.jenkins_vm, oci_core_public_ip.jenkins_public_ip]

  provisioner "file" {
    content     = data.template_file.jenkins_docker_compose.rendered
    destination = "/home/opc/jenkins.yaml"

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

    }
  }

  provisioner "file" {
    content     = file("${path.module}/scripts/Dockerfile")
    destination = "/home/opc/Dockerfile"

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

    }
  }

  provisioner "file" {
    content     = file("${path.module}/scripts/casc.yaml")
    destination = "/home/opc/casc.yaml"

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

    }
  }

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
      type                = "ssh"
      agent               = false
      user                = opc
      host                = oci_core_public_ip.jenkins_public_ip.ip_address
      private_key         = tls_private_key.tls_key_pair.private_key_pem
    }
    source      = local_file.database_wallet_file.filename
    # Place in an existing directory; cloud-init will move it
    destination = "/home/opc/wallet/adb_wallet.zip"
  }
}
