data "oci_core_images" "instance_images" {
  compartment_id           = var.compartment_id
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.instance_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.compartment_id
}

data "oci_core_vnic_attachments" "jenkins_vnics" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain_name
  instance_id         = oci_core_instance.jenkins_vm.id
}

data "oci_core_vnic" "jenkins_vnic" {
  vnic_id = data.oci_core_vnic_attachments.jenkins_vnics.vnic_attachments[0]["vnic_id"]
}

data "oci_core_private_ips" "jenkins_private_ip" {
  vnic_id = data.oci_core_vnic.jenkins_vnic.id
}