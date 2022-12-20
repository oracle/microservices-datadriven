resource "oci_core_virtual_network" "jenkins_vcn" {
  compartment_id = var.compartment_id
  cidr_block     = var.vcn_cidr
  display_name   = var.vcn_name
  dns_label      = var.vcn_dns
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id
  display_name   = "${var.vcn_name}-igw"
}

resource "oci_core_route_table" "pub_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id
  display_name   = "${var.vcn_name}-pub-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "pub_sl_ssh" {
  compartment_id = var.compartment_id
  display_name   = "Allow Public SSH Connections to Jenkins"
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "pub_sl_http" {
  compartment_id = var.compartment_id
  display_name   = "Allow HTTP(S) to Jenkins"
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6"
  }

  ingress_security_rules {
    tcp_options {
      max = 80
      min = 80
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "pub_jenkins_subnet" {
  compartment_id = var.compartment_id
  cidr_block     = cidrsubnet(var.vcn_cidr, 8, 0)
  display_name   = "${var.vcn_name}-pub-subnet"

  vcn_id            = oci_core_virtual_network.jenkins_vcn.id
  route_table_id    = oci_core_route_table.pub_rt.id
  security_list_ids = [oci_core_security_list.pub_sl_ssh.id, oci_core_security_list.pub_sl_http.id]
  dhcp_options_id   = oci_core_virtual_network.jenkins_vcn.default_dhcp_options_id

  dns_label = var.subnet_dns
}