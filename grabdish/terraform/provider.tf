terraform {
  required_providers {
    oci = {
      source = "hashicorp/oci"
      version = "4.42.0"
    }
  }
}

provider "oci" {
  region           = var.ociRegionIdentifier
}