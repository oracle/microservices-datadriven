
terraform {
  required_providers {

    oci = {
      source = "hashicorp/oci"
    }
    random = {
      source = "hashicorp/random"
    }

  }
  required_version = ">= 0.14"
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region = var.region
  user_ocid = var.user_ocid
  fingerprint = var.fingerprint
  private_key_path = var.private_key_path
}
