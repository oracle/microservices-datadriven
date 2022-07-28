# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_availability_domain" "availability_domains" {
  compartment_id = var.tenancy_ocid
  ad_number = 1
}
