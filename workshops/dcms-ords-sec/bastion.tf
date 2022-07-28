# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_bastion_bastion" "bastion_service" {
  compartment_id               = var.compartment_ocid
  bastion_type                 = "STANDARD"
  target_subnet_id             = oci_core_subnet.subnet_public.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = format("%sBastionService", upper(var.proj_abrv))
  max_session_ttl_in_seconds   = 10800
}

// Needed so the compute instance and bastion plugin is upa nd running.
resource "time_sleep" "wait_4_minutes_for_bastion_plugin" {
  count           = var.create_bastion_session ? 1 : 0
  depends_on      = [oci_core_instance.instance]
  create_duration = "4m"
  triggers = {
    compute_id = oci_core_instance.instance.id
  }
}

// Create a file called bastion_key with the private key used for the bastion in terraform
resource "local_file" "private_key" {
  count           = var.create_bastion_session ? 1 : 0
  content         = tls_private_key.example_com.private_key_openssh
  filename        = "${path.module}/bastion_key"
  file_permission = 0600
}

resource "oci_bastion_session" "session_managed_ssh" {
  count      = var.create_bastion_session ? 1 : 0
  bastion_id = oci_bastion_bastion.bastion_service.id
  key_details {
    public_key_content = tls_private_key.example_com.public_key_openssh
  }
  target_resource_details {

    session_type       = "MANAGED_SSH"
    target_resource_id = oci_core_instance.instance.id

    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.instance.private_ip
  }

  display_name           = format("%s-bastion-ssh", upper(var.proj_abrv))
  key_type               = "PUB"
  # Session will live for 3 hours
  session_ttl_in_seconds = 10800

  depends_on = [time_sleep.wait_4_minutes_for_bastion_plugin]
}

resource "oci_bastion_session" "session_forward_ssh" {
  count      = var.create_bastion_session ? 1 : 0
  bastion_id = oci_bastion_bastion.bastion_service.id
  key_details {
    public_key_content = tls_private_key.example_com.public_key_openssh
  }
  target_resource_details {

    session_type         = "PORT_FORWARDING"

    target_resource_port                = 1521
    target_resource_private_ip_address  = oci_database_autonomous_database.autonomous_database.private_endpoint_ip
  }

  display_name           = format("%s-port-forward", upper(var.proj_abrv))
  key_type               = "PUB"
  # Session will live for 3 hours
  session_ttl_in_seconds = 10800

  depends_on = [time_sleep.wait_4_minutes_for_bastion_plugin]
}
