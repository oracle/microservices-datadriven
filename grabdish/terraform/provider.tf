terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5"
    }
  }
  required_version = "~> 1.2"
}

provider "oci" {
  region = var.ociRegionIdentifier
}
