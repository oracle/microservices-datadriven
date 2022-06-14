# Copyright © 2020, Oracle and/or its affiliates. 
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

// If this is ALF, need to determine which AD can create CI's in
data "oci_limits_limit_values" "limits_limit_values" {
  compartment_id = var.tenancy_ocid
  service_name   = "compute"
  scope_type     = "AD"
  name           = "vm-standard-e2-1-micro-count"
  filter {
    name   = "value"
    values = ["2"]
  }    
}

// If we have a value from limits, use that as ALF, otherwise use AD-1
locals {
  availability_domain = length(data.oci_limits_limit_values.limits_limit_values.limit_values.*.availability_domain) != 0 ? data.oci_limits_limit_values.limits_limit_values.limit_values[0].availability_domain : data.oci_identity_availability_domains.availability_domains.availability_domains[0]["name"]
}