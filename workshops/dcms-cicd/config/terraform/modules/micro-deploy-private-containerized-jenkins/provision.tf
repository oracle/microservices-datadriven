data "template_file" "jenkins_docker_compose" {
  template = file("${path.module}/scripts/jenkins.yaml")

  vars = {
    jenkins_user     = var.jenkins_user,
    jenkins_password = var.jenkins_password
  }
}

resource "null_resource" "jenkins_provisioner" {
  depends_on = [oci_core_instance.jenkins_vm, oci_bastion_session.bastion_session]

  provisioner "file" {
    content     = data.template_file.jenkins_docker_compose.rendered
    destination = "/home/opc/jenkins.yaml"

    connection {
      host        = oci_core_instance.jenkins_vm.private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_session.id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = file("${path.module}/scripts/Dockerfile")
    destination = "/home/opc/Dockerfile"

    connection {
      host        = oci_core_instance.jenkins_vm.private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_session.id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem

    }
  }

  provisioner "file" {
    content     = file("${path.module}/scripts/casc.yaml")
    destination = "/home/opc/casc.yaml"

    connection {
      host        = oci_core_instance.jenkins_vm.private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem


      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_session.id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem

    }

  }

  provisioner "remote-exec" {
    connection {
      host        = oci_core_instance.jenkins_vm.private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_session.id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem
    }

    inline = [
      "while [ ! -f /tmp/cloud-init-complete ]; do sleep 1; done",
      "docker-compose -f /home/opc/jenkins.yaml up -d"
    ]

  }
}


