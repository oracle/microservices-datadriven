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

resource "oci_core_nat_gateway" "ngw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id
  display_name   = "${var.vcn_name}-nat"
}

resource "oci_core_route_table" "pub_lb_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id
  display_name   = "${var.vcn_name}-pub-lb-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "prv_subnet_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id
  display_name   = "${var.vcn_name}-prv-subnet-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.ngw.id
  }
}

resource "oci_core_security_list" "pub_sl_http" {
  compartment_id = var.compartment_id
  display_name   = "Allow HTTP(S) Connections to Jenkins"
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

resource "oci_core_subnet" "pub_jenkins_lb_subnet" {
  compartment_id = var.compartment_id
  cidr_block     = cidrsubnet(var.vcn_cidr, 8, 1)
  display_name   = "${var.vcn_name}-pub-lb-subnet"

  vcn_id            = oci_core_virtual_network.jenkins_vcn.id
  route_table_id    = oci_core_route_table.pub_lb_rt.id
  security_list_ids = [oci_core_security_list.pub_sl_http.id]
  dhcp_options_id   = oci_core_virtual_network.jenkins_vcn.default_dhcp_options_id

  dns_label = "jnkslbpub"
}

resource "oci_core_security_list" "priv_sl_lb_http" {
  compartment_id = var.compartment_id
  display_name   = "Allow HTTP(s) Connections to Jenkins through the LB Subnet"
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
    source   = cidrsubnet(var.vcn_cidr, 8, 1)
  }

  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }
    protocol = "6"
    source   = cidrsubnet(var.vcn_cidr, 8, 1)
  }
}

resource "oci_core_security_list" "priv_sl_bastion_ssh" {
  compartment_id = var.compartment_id
  display_name   = "Allow SSH Connections to Jenkins VM from the Bastion"
  vcn_id         = oci_core_virtual_network.jenkins_vcn.id


  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }
    protocol = "6"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "prv_jenkins_controller_subnet" {
  compartment_id = var.compartment_id
  cidr_block     = cidrsubnet(var.vcn_cidr, 8, 3)
  display_name   = "${var.vcn_name}-prv-ctlr-subnet"

  vcn_id            = oci_core_virtual_network.jenkins_vcn.id
  route_table_id    = oci_core_route_table.prv_subnet_rt.id
  security_list_ids = [oci_core_security_list.priv_sl_lb_http.id, oci_core_security_list.priv_sl_bastion_ssh.id]
  dhcp_options_id   = oci_core_virtual_network.jenkins_vcn.default_dhcp_options_id

  prohibit_public_ip_on_vnic = true
  dns_label                  = "jnkscntrlpriv"
}
