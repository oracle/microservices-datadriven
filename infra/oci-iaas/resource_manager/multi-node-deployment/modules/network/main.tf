locals {
  compartment_id    = var.target_compartment_id
  display_name      = "microservices"
  vcn_dns_label     = "onpremise"
  vcn_cidr_block    = "10.0.0.0/16"
  subnet_cidr_block = "10.0.1.0/24"
  all_cidr          = "0.0.0.0/0"
  vcn_id = oci_core_vcn.this.id
}

# VCN
resource "oci_core_vcn" "this" {
  compartment_id = local.compartment_id
  cidr_block     = local.vcn_cidr_block
  display_name   = "${local.display_name}-vcn"
  dns_label      = local.vcn_dns_label
  freeform_tags  = var.common_tags
}

# internet gateway to connect to compute instance - internet gateway is for the VCN

resource "oci_core_internet_gateway" "ig" {
  # count          = local.use_existing_vcn ? 0 : 1
  compartment_id = local.compartment_id                     # Required
  vcn_id         = local.vcn_id                             # Required
  display_name   = "${local.display_name}-internet-gateway" # Optional
  freeform_tags  = var.common_tags
}

resource "oci_core_route_table" "rt" { #TODO - change the name to "rt" instead of "subnet"
  # count          = local.use_existing_vcn ? 0 : 1
  compartment_id = local.compartment_id
  vcn_id         = local.vcn_id
  display_name   = "${local.display_name}-route-table"

  route_rules {
    destination       = local.all_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }

  freeform_tags = var.common_tags
}

resource "oci_core_security_list" "sl" {
  compartment_id = local.compartment_id                  # Required
  vcn_id         = local.vcn_id                          # Required
  display_name   = "${local.display_name}-security-list" # Optional
  freeform_tags  = var.common_tags

  # Intentionally left ingress and egress rules blank. Expected to set the NSG at the instance level
}

#subnet
resource "oci_core_subnet" "regional_sn" {
  cidr_block        = local.subnet_cidr_block        # Required
  compartment_id    = var.target_compartment_id      # Required
  vcn_id            = local.vcn_id                   # Required
  route_table_id    = oci_core_route_table.rt.id     # Optional - But Required in this case to associate the above created Route table
  security_list_ids = [oci_core_security_list.sl.id] # Optional - defined a security list that has NO ingress and egress rules
  display_name      = "${local.display_name}-subnet" # Optional
  freeform_tags     = var.common_tags
  dns_label         = local.display_name
  //prohibit_public_ip_on_vnic = false
}
