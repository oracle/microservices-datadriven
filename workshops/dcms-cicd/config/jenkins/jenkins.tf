
data "template_file" "jenkins-docker-compose" {
  template = file("${path.module}/scripts/jenkins.yaml")

  vars = {
    public_key_openssh = tls_private_key.public_private_key_pair.public_key_openssh,
    jenkins_user       = var.jenkins_user,
    jenkins_password   = var.jenkins_password
  }
}

resource "oci_core_instance" "Jenkins" {
  availability_domain = local.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "Jenkins"
  shape               = local.instance_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_instance_shape ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_shape_config_memory_in_gbs
    }
  }


  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    display_name     = "primaryvnic"
    assign_public_ip = false
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.InstanceImageOCID.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.public_private_key_pair.public_key_openssh : join("\n", [var.public_ssh_key, tls_private_key.public_private_key_pair.public_key_openssh])
    user_data = base64encode(templatefile("./scripts/setup-docker.yaml",
      {
        jenkins_user     = var.jenkins_user,
        jenkins_password = var.jenkins_password
    }))
  }

}

data "oci_core_vnic_attachments" "Jenkins_vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain_name
  instance_id         = oci_core_instance.Jenkins.id
}

data "oci_core_vnic" "Jenkins_vnic1" {
  vnic_id = data.oci_core_vnic_attachments.Jenkins_vnics.vnic_attachments[0]["vnic_id"]
}

data "oci_core_private_ips" "Jenkins_private_ips1" {
  vnic_id = data.oci_core_vnic.Jenkins_vnic1.id
}

resource "oci_core_public_ip" "Jenkins_public_ip" {
  compartment_id = var.compartment_ocid
  display_name   = "Jenkins_public_ip"
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.Jenkins_private_ips1.private_ips[0]["id"]
}

resource "null_resource" "Jenkins_provisioner" {
  depends_on = [oci_core_instance.Jenkins, oci_core_public_ip.Jenkins_public_ip]

  provisioner "file" {
    content     = data.template_file.jenkins-docker-compose.rendered
    destination = "/home/opc/jenkins.yaml"

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.Jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem

    }
  }

  provisioner "file" {
    content     = file("${path.module}/scripts/Dockerfile")
    destination = "/home/opc/Dockerfile"

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.Jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem

    }
  }

  provisioner "file" {
    content     = file("${path.module}/scripts/casc.yaml")
    destination = "/home/opc/casc.yaml"

    connection {
      type        = "ssh"
      host        = oci_core_public_ip.Jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem

    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = oci_core_public_ip.Jenkins_public_ip.ip_address
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = tls_private_key.public_private_key_pair.private_key_pem

    }

    inline = [
      "while [ ! -f /tmp/cloud-init-complete ]; do sleep 1; done",
      "docker-compose -f /home/opc/jenkins.yaml up -d"
    ]

  }
}

locals {
  availability_domain_name   = var.availability_domain_name != null ? var.availability_domain_name : data.oci_identity_availability_domains.ADs.availability_domains[0].name
  instance_shape             = var.instance_shape
  compute_flexible_shapes    = ["VM.Standard.E3.Flex","VM.Standard.E4.Flex"]
  is_flexible_instance_shape = contains(local.compute_flexible_shapes, local.instance_shape)
}
