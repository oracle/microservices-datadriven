resource "oci_core_vcn" "vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.ociCompartmentOcid
  display_name   = var.vcnDnsName
  dns_label    = var.vcnDnsName
}

resource "oci_core_internet_gateway" "ig" {
   compartment_id = var.ociCompartmentOcid
   vcn_id         = oci_core_vcn.vcn.id
}

resource oci_core_nat_gateway ngw {
  block_traffic  = "false"
  compartment_id = var.ociCompartmentOcid
  vcn_id       = oci_core_vcn.vcn.id
}

resource oci_core_service_gateway sg {
  compartment_id = var.ociCompartmentOcid
  services {
    service_id = data.oci_core_services.services.services.0.id
  }
  vcn_id = oci_core_vcn.vcn.id
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
  vcn_id = oci_core_vcn.vcn.id
}

resource oci_core_default_route_table public {
  display_name = "public"
  freeform_tags = {
  }
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id
  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

resource oci_core_default_security_list public {
  display_name = "public"
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}

data "oci_core_services" "services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

output "vcn_ocid" {
  value = oci_core_vcn.vcn.id
}