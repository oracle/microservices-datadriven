output "vcn" {
  value = oci_core_vcn.this
}

output "subnet" {
  value = oci_core_subnet.regional_sn
}

output "subnet_domain_name" {
  value = oci_core_subnet.regional_sn.subnet_domain_name
}
