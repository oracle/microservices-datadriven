//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  endpoint_cidr_block = "10.0.0.0/28"
  nodepool_cidr_block = "10.0.10.0/24"
  svclb_cidr_block    = "10.0.20.0/24"
}

data "oci_core_vcn" "vcn" {
  #Required
  vcn_id = var.vcnOcid
}

data "oci_core_nat_gateways" "ngws" {
  compartment_id = var.ociCompartmentOcid
  vcn_id         = data.oci_core_vcn.vcn.id
}

data "oci_core_service_gateways" "sgs" {
  compartment_id = var.ociCompartmentOcid
  vcn_id         = data.oci_core_vcn.vcn.id
}

resource "oci_core_route_table" "private" {
  compartment_id = var.ociCompartmentOcid
  display_name   = "private"
  freeform_tags = {
  }
  route_rules {
    description       = "traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_nat_gateways.ngws.nat_gateways.0.id
  }
  route_rules {
    description       = "traffic to OCI services"
    destination       = data.oci_core_services.services.services.0.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = data.oci_core_service_gateways.sgs.service_gateways.0.id
  }
  vcn_id = data.oci_core_vcn.vcn.id
}

resource "oci_core_subnet" "endpoint" {
  cidr_block                 = local.endpoint_cidr_block
  compartment_id             = var.ociCompartmentOcid
  vcn_id                     = data.oci_core_vcn.vcn.id
  security_list_ids          = [oci_core_security_list.endpoint.id]
  display_name               = "Endpoint"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = data.oci_core_vcn.vcn.default_route_table_id
  dns_label                  = "endpoint"
}

resource "oci_core_subnet" "nodepool" {
  cidr_block                 = local.nodepool_cidr_block
  compartment_id             = var.ociCompartmentOcid
  vcn_id                     = data.oci_core_vcn.vcn.id
  security_list_ids          = [oci_core_security_list.nodepool.id]
  display_name               = "Node Pool"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.private.id
  dns_label                  = "nodepool"
}

resource "oci_core_subnet" "svclb" {
  cidr_block                 = local.svclb_cidr_block
  compartment_id             = var.ociCompartmentOcid
  vcn_id                     = data.oci_core_vcn.vcn.id
  security_list_ids          = [data.oci_core_vcn.vcn.default_security_list_id]
  display_name               = "Service Load Balancer"
  route_table_id             = data.oci_core_vcn.vcn.default_route_table_id
  dhcp_options_id            = data.oci_core_vcn.vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = "false"
  dns_label                  = "svclb"
}

resource "oci_core_security_list" "nodepool" {
  compartment_id = var.ociCompartmentOcid
  display_name   = "Node Pool"
  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = local.nodepool_cidr_block
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = local.endpoint_cidr_block
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = local.endpoint_cidr_block
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = local.endpoint_cidr_block
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning (0)"
    destination      = data.oci_core_services.services.services.0.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  freeform_tags = {
  }
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    protocol    = "all"
    source      = local.nodepool_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = local.endpoint_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    protocol    = "6"
    source      = local.endpoint_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Inbound SSH traffic to worker nodes"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  vcn_id = data.oci_core_vcn.vcn.id
}

resource "oci_core_security_list" "endpoint" {
  compartment_id = var.ociCompartmentOcid
  display_name   = "Endpoint"
  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = data.oci_core_services.services.services.0.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = local.nodepool_cidr_block
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = local.nodepool_cidr_block
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  freeform_tags = {
  }
  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    protocol    = "6"
    source      = local.nodepool_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to control plane communication"
    protocol    = "6"
    source      = local.nodepool_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = local.nodepool_cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  vcn_id = data.oci_core_vcn.vcn.id
}

resource "oci_core_default_security_list" "svcLB" {
  display_name               = "Service Load Balancer"
  manage_default_resource_id = data.oci_core_vcn.vcn.default_security_list_id
}

data "oci_core_services" "services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}