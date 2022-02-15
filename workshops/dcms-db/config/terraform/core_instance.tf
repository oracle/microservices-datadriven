# Copyright © 2020, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

// Get the latest Oracle Linux image
data "oci_core_images" "images" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.compute_os
  operating_system_version = var.linux_os_version
  shape                    = local.compute_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

resource "oci_core_instance" "instance" {
  compartment_id      = var.compartment_ocid
  display_name        = format("%s-ords-core", var.proj_abrv)
  availability_domain = local.availability_domain
  shape               = local.compute_shape
  dynamic "shape_config" {
    for_each = local.is_flexible_shape ? [1] : []
    content {
      baseline_ocpu_utilization = "BASELINE_1_2"
      ocpus                     = var.compute_flex_shape_ocpus[var.size]
      // Memory OCPU * 16GB
      memory_in_gbs             = var.compute_flex_shape_ocpus[var.size] * 16
    }
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.images.images[0].id
  }
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false
    plugins_config  {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }
  // If this is ALF, we can't place in the private subnet as need access to the cloud agent/packages
  create_vnic_details {
    subnet_id        = local.is_always_free ? oci_core_subnet.subnet_public.id: oci_core_subnet.subnet_private[0].id
    assign_public_ip = local.is_always_free
    nsg_ids          = [oci_core_network_security_group.security_group_ssh.id, oci_core_network_security_group.security_group_ords.id]
  }
  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_file)
  }
  lifecycle {
    ignore_changes = all
  }
}
