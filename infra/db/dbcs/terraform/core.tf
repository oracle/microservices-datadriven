//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
    db_cidr_block = "10.0.30.0/24"
}

data "oci_core_vcn" "vcn" {
    #Required
    vcn_id = var.vcnOcid
}

data "oci_core_nat_gateways" "ngws" {
    compartment_id = var.ociCompartmentOcid
    vcn_id = data.oci_core_vcn.vcn.id
}

resource oci_core_route_table db {
  compartment_id = var.ociCompartmentOcid
  display_name = "db"
  freeform_tags = {
  }
  route_rules {
    description       = "traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_nat_gateways.ngws.nat_gateways.0.id
  }
  vcn_id = data.oci_core_vcn.vcn.id
}

resource "oci_core_subnet" "db" {
  cidr_block          = local.db_cidr_block
  compartment_id      = var.ociCompartmentOcid
  vcn_id              = data.oci_core_vcn.vcn.id
  security_list_ids = [oci_core_security_list.db.id]
  display_name      = "DB"
  prohibit_public_ip_on_vnic = "true"
  route_table_id    = oci_core_route_table.db.id
  dns_label           = "db"
}

resource oci_core_security_list db {
  compartment_id = var.ociCompartmentOcid
  display_name = "DB"
  egress_security_rules {
    description      = "All traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol = "all"
    stateless = "false"
  }
  ingress_security_rules {
    description = "SSH"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    description = "Path MTU Discovery fragmentation messages"
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    icmp_options {
      code = "4"
      type = "3"
    }
  }
  ingress_security_rules {
    description = "ICMP"
    protocol    = "1"
    source      = data.oci_core_vcn.vcn.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    icmp_options {
      type = "3"
    }
  }
  ingress_security_rules {
    description = "ONS and FAN"
    protocol    = "6"
    source      = data.oci_core_vcn.vcn.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6200"
      min = "6200"
    }
  }
  ingress_security_rules {
    description = "SQL*NET"
    protocol    = "6"
    source      = data.oci_core_vcn.vcn.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "1521"
      min = "1521"
    }
  }
  vcn_id = data.oci_core_vcn.vcn.id
}