data "template_file" "jenkins_docker_compose" {
  template = file("${path.module}/controller/jenkins.yaml")

  vars = {
    jenkins_user     = var.jenkins_user,
    jenkins_password = var.jenkins_password
  }
}

data "template_file" "agent_setup" {
  depends_on = [oci_core_instance.jenkins_vm]
  for_each   = toset(var.unique_agent_names)
  template   = file("${path.module}/agent/setup.sh")

  vars = {
    jenkins_endpoint   = "http://${oci_core_instance.jenkins_vm.private_ip}",
    jenkins_user       = var.jenkins_user
    jenkins_password   = var.jenkins_password
    jenkins_agent_name = each.value
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
    content     = file("${path.module}/controller/Dockerfile")
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
    content     = file("${path.module}/controller/casc.yaml")
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


resource "null_resource" "agents_provisioner" {
  depends_on = [
    oci_bastion_session.bastion_agent_session,
    oci_core_instance.agent_vm,
    null_resource.jenkins_provisioner
  ]
  for_each = toset(var.unique_agent_names)

  provisioner "file" {

    content     = file("${path.module}/agent/agent.yaml")
    destination = "/home/opc/agent.yaml"

    connection {
      host        = oci_core_instance.agent_vm[each.key].private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_agent_session[each.key].id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem
    }
  }

  provisioner "file" {
    content     = file("${path.module}/agent/Dockerfile")
    destination = "/home/opc/Dockerfile"

    connection {
      host        = oci_core_instance.agent_vm[each.key].private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_agent_session[each.key].id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem

    }
  }

  provisioner "file" {
    content     = file("${path.module}/agent/config.xml")
    destination = "/home/opc/config.xml"

    connection {
      host        = oci_core_instance.agent_vm[each.key].private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem


      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_agent_session[each.key].id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem

    }

  }

  provisioner "file" {
    content     = data.template_file.agent_setup[each.key].rendered
    destination = "/home/opc/setup.sh"

    connection {
      host        = oci_core_instance.agent_vm[each.key].private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem


      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_agent_session[each.key].id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem

    }

  }

  provisioner "remote-exec" {

    connection {
      host        = oci_core_instance.agent_vm[each.key].private_ip
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.tls_key_pair.private_key_pem

      bastion_host        = "host.bastion.${var.region}.oci.oraclecloud.com"
      bastion_user        = oci_bastion_session.bastion_agent_session[each.key].id
      bastion_private_key = tls_private_key.tls_key_pair.private_key_pem
    }

    inline = [
      "chmod +x /home/opc/setup.sh",
      "sh /home/opc/setup.sh"
    ]

  }
}

