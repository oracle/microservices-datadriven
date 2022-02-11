# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_bastion_bastion" "bastion_service" {
  compartment_id               = var.compartment_ocid
  bastion_type                 = "STANDARD"
  target_subnet_id             = oci_core_subnet.subnet_public.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = format("%sBastionService", var.proj_abrv)
  max_session_ttl_in_seconds   = 10800
}

// Need to wait for the Plugin to Start
resource "null_resource" "bastion_patience" {
    depends_on = [ oci_core_instance.instance ]
    provisioner "local-exec" {
      command = "sleep 240"
    }
}

resource "oci_bastion_session" "bastion_service_ssh" {
  depends_on = [ null_resource.bastion_patience ]
  bastion_id = oci_bastion_bastion.bastion_service.id

  key_details {
    public_key_content = tls_private_key.example_com.public_key_openssh
  }

  target_resource_details {
    session_type                               = "MANAGED_SSH"
    target_resource_id                         = oci_core_instance.instance.id
    target_resource_operating_system_user_name = var.bastion_user
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.instance.private_ip
  }

  display_name           = format("%s-bastion-service-ssh", var.proj_abrv)
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}