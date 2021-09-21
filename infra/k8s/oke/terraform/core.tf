//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_core_vcn" "okell_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.ociCompartmentOcid
  display_name   = "grabdish"
  dns_label    = "grabdish"
}
resource "oci_core_internet_gateway" "ig" {
   compartment_id = var.ociCompartmentOcid
   display_name   = "ClusterInternetGateway"
   vcn_id         = oci_core_vcn.okell_vcn.id
}
resource oci_core_nat_gateway ngw {
  block_traffic  = "false"
  compartment_id = var.ociCompartmentOcid
  display_name = "ngw"
  freeform_tags = {
  }
  vcn_id       = oci_core_vcn.okell_vcn.id
}
resource oci_core_service_gateway sg {
  compartment_id = var.ociCompartmentOcid
  display_name = "grabdish"
  freeform_tags = {
  }
  services {
    service_id = data.oci_core_services.services.services.0.id
  }
  vcn_id = oci_core_vcn.okell_vcn.id
}
resource oci_core_route_table private {
  compartment_id = var.ociCompartmentOcid
  display_name = "private"
  freeform_tags = {
  }
  route_rules {
    description       = "traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }
  route_rules {
    description       = "traffic to OCI services"
    destination       = data.oci_core_services.services.services.0.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sg.id
  }
  vcn_id = oci_core_vcn.okell_vcn.id
}
resource oci_core_default_route_table public {
  display_name = "public"
  freeform_tags = {
  }
  manage_default_resource_id = oci_core_vcn.okell_vcn.default_route_table_id
  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}
resource "oci_core_subnet" "endpoint_Subnet" {
  cidr_block          = "10.0.0.0/28"
  compartment_id      = var.ociCompartmentOcid
  vcn_id              = oci_core_vcn.okell_vcn.id
  security_list_ids   = [oci_core_security_list.endpoint.id]
  display_name        = "SubNet1ForEndpoint"
  prohibit_public_ip_on_vnic = "false"
  route_table_id      = oci_core_vcn.okell_vcn.default_route_table_id
  dns_label           = "endpoint"
}
resource "oci_core_subnet" "nodePool_Subnet" {
  cidr_block          = "10.0.10.0/24"
  compartment_id      = var.ociCompartmentOcid
  vcn_id              = oci_core_vcn.okell_vcn.id
  security_list_ids = [oci_core_security_list.nodePool.id]
  display_name      = "SubNet1ForNodePool"
  prohibit_public_ip_on_vnic = "true"
  route_table_id    = oci_core_route_table.private.id
  dns_label           = "nodepool"
}
resource "oci_core_subnet" "svclb_Subnet" {
  cidr_block          = "10.0.20.0/24"
  compartment_id      = var.ociCompartmentOcid
  vcn_id              = oci_core_vcn.okell_vcn.id
  security_list_ids = [oci_core_default_security_list.svcLB.id]
  display_name      = "SubNet1ForSvcLB"
  route_table_id    = oci_core_vcn.okell_vcn.default_route_table_id
  dhcp_options_id = oci_core_vcn.okell_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = "false"
  dns_label           = "svclb"
}
resource oci_core_security_list nodePool {
  compartment_id = var.ociCompartmentOcid
  display_name = "nodepool"
  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol  = "all"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "6443"
      min = "6443"
    }
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "12250"
      min = "12250"
    }
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.0.0/28"
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
    protocol  = "6"
    stateless = "false"
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
    protocol  = "all"
    stateless = "false"
   }
  freeform_tags = {
  }
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    protocol    = "all"
    source      = "10.0.10.0/24"
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
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    protocol    = "6"
    source      = "10.0.0.0/28"
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
  vcn_id = oci_core_vcn.okell_vcn.id
}

resource oci_core_security_list endpoint {
  compartment_id = var.ociCompartmentOcid
  display_name = "endpoint"
  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = data.oci_core_services.services.services.0.cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol  = "6"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.10.0/24"
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
    source      = "10.0.10.0/24"
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
    source      = "10.0.10.0/24"
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
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  vcn_id = oci_core_vcn.okell_vcn.id
}

resource oci_core_default_security_list svcLB {
  display_name = "svcLB"
  manage_default_resource_id = oci_core_vcn.okell_vcn.default_security_list_id
}
data "oci_core_services" "services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}