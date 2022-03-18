// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_database_autonomous_databases" "autonomous_databases_atp" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  display_name = var.autonomous_database_display_name
  db_workload  = var.autonomous_database_db_workload
}

