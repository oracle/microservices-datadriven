# Copyright © 2020, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

// While cloud-init could be used to install software, still need to send up wallet
// so instead of complicating with different ways to bootstrap the ORDS, using provisioners :()
locals {
  db_name  = lookup(oci_database_autonomous_database.autonomous_database,"db_name")
  password = random_password.autonomous_database_password.result
  apex_ver = lookup(oci_database_autonomous_database.autonomous_database.apex_details[0],"apex_version")
}

data "oci_core_vnic_attachments" "instance_vnic_attach" {
  availability_domain = local.availability_domain
  compartment_id      = var.compartment_ocid
  instance_id         = oci_core_instance.instance.id
}

data "oci_core_vnic" "instance_vnic" {
  vnic_id = data.oci_core_vnic_attachments.instance_vnic_attach.vnic_attachments.0.vnic_id
}

resource "null_resource" "ords_root_config" {
  depends_on = [oci_core_instance.instance]
  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = oci_core_instance.instance.public_ip
      private_key         = chomp(file(var.ssh_private_key_file))
      agent               = false
      timeout             = "10m"
    }
    source      = "uploads"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = oci_core_instance.instance.public_ip
      private_key         = chomp(file(var.ssh_private_key_file))
      agent               = false
      timeout             = "10m"
    }
    inline = [
      "sudo chmod +x /tmp/uploads/config_*.sh",
      "sudo -u root /tmp/uploads/config_root.sh -s PRE"
    ]
  }
}

resource "null_resource" "ords_oracle_config" {
  depends_on = [null_resource.ords_root_config, oci_database_autonomous_database.autonomous_database, local_file.database_wallet_file]
  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = oci_core_instance.instance.public_ip
      private_key         = chomp(file(var.ssh_private_key_file))
      agent               = false
      timeout             = "10m"
    }
    source      = "uploads"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = oci_core_instance.instance.public_ip
      private_key         = chomp(file(var.ssh_private_key_file))
      agent               = false
      timeout             = "10m"
    }
    inline = [
//      "sudo -u oracle /tmp/uploads/config_oracle.sh -t ${local.db_name} -p \"${local.password}\" -v ${local.apex_ver}",
//      "sudo -u oracle /tmp/uploads/config_oracle.sh -t ${local.db_name} -p \"${local.password}\" -v 21.1.7",
//      "sudo -u root /tmp/uploads/config_root.sh -s POST"
      "echo"
    ]
  }
}
