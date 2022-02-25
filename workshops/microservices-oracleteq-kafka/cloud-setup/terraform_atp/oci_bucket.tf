//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Variables
# variable "compartment_id"   { type = string }
# variable "bucket_name"      { type = string }
variable "runName" {}

variable "bucket_namespace" {
  type = string
  default = "maacloud"

}

variable "bucket_access_type" {
  type    = string
  default = "NoPublicAccess"
}


# Resources
resource "oci_objectstorage_bucket" "tf_bucket" {
  compartment_id = var.compartment_ocid
  name           = var.runName
  namespace      = var.bucket_namespace
  access_type    = var.bucket_access_type
}


# Outputs
output "bucket_name" {
  value = oci_objectstorage_bucket.tf_bucket.name
}

output "bucket_id" {
  value = oci_objectstorage_bucket.tf_bucket.bucket_id
}