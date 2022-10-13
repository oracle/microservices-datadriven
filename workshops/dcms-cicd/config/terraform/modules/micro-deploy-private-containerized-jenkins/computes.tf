resource "oci_core_instance" "jenkins_vm" {
  availability_domain = local.availability_domain_name
  compartment_id      = var.compartment_id
  display_name        = "jenkins-vm"
  shape               = local.instance_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_instance_shape ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_shape_config_memory_in_gbs
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.prv_jenkins_controller_subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = false
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.instance_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.generate_public_ssh_key ? tls_private_key.tls_key_pair.public_key_openssh : join("\n", [var.public_ssh_key, tls_private_key.tls_key_pair.public_key_openssh])
    user_data = base64encode(templatefile("${path.module}/scripts/cloud-init.yaml",
      {
        jenkins_user     = var.jenkins_user,
        jenkins_password = var.jenkins_password
    }))
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }

}