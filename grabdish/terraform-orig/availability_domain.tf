data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.ociTenancyOcid
  ad_number      = 1
}