# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "vcn" {
  compartment_id = local.compartment_ocid
  display_name   = format("%s-vcn", upper(var.proj_abrv))
  cidr_block     = var.vcn_cidr
  is_ipv6enabled = var.vcn_is_ipv6enabled
  dns_label      = var.proj_abrv
}

resource "oci_core_default_security_list" "export_Default-Security-List-for-apexpoc-vcn" {
  compartment_id = local.compartment_ocid
  display_name = "Default Security List"
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    icmp_options {
      code = "-1"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}

#####################################################################
## Always Free + Paid Resources
#####################################################################
resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-internet-gateway", upper(var.proj_abrv))
}

resource "oci_core_route_table" "route_table_internet_gw" {
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-route-table-internet-gw", upper(var.proj_abrv))
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_subnet" "subnet_public" {
  compartment_id             = local.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = format("%s-subnet-public", upper(var.proj_abrv))
  cidr_block                 = var.public_subnet_cidr
  route_table_id             = oci_core_route_table.route_table_internet_gw.id
  dhcp_options_id            = oci_core_vcn.vcn.default_dhcp_options_id
  dns_label                  = "publ"
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_nat_gateway" "nat_gateway" {
  count          = local.is_paid ? 1 : 0
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-nat-gateway", upper(var.proj_abrv))
}

resource "oci_core_route_table" "route_table_nat_gw" {
  count          = local.is_paid ? 1 : 0
  compartment_id = local.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = format("%s-route-table-nat-gw", upper(var.proj_abrv))
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway[count.index].id
  }
}

resource "oci_core_subnet" "subnet_private" {
  count                      = local.is_paid ? 1 : 0
  compartment_id             = local.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = format("%s-subnet-private", upper(var.proj_abrv))
  cidr_block                 = var.private_subnet_cidr
  route_table_id             = oci_core_route_table.route_table_nat_gw[0].id
  dhcp_options_id            = oci_core_vcn.vcn.default_dhcp_options_id
  dns_label                  = "priv"
  prohibit_public_ip_on_vnic = true
  // This is to prevent the attempt to destroy the NSG before the subnet (VNIC attachment)
  depends_on = [
    oci_core_network_security_group.security_group_adb
  ]
}

data "oci_core_services" "service_gw_service" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "service_gateway" {
	#Required
	compartment_id = local.compartment_ocid
	services {
		#Required
		service_id = data.oci_core_services.service_gw_service.services[0]["id"]
	}
	vcn_id = oci_core_vcn.vcn.id
	display_name = format("%s-service-gateway", upper(var.proj_abrv))
}

resource "oci_core_route_table" "sgw_route_table" {
  compartment_id = local.compartment_ocid
  vcn_id         =  oci_core_vcn.vcn.id
  display_name   = format("%s-route-table-service-gw", upper(var.proj_abrv))

  route_rules {
    destination       = data.oci_core_services.service_gw_service.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
  }
}
