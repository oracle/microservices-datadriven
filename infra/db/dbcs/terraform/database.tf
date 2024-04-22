//Copyright (c) 2021 Oracle and/or its affiliates.
//Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "random_password" "database_admin_password" {
  length  = 12
  upper   = true
  lower   = true
  numeric  = true
  special = true
  min_lower = "2"
  min_upper = "2"
  min_numeric = "2"
  min_special = "2"
  override_special = "-_#"
}

resource "oci_database_db_system" "dbs" {
  compartment_id = var.ociCompartmentOcid
  subnet_id = oci_core_subnet.db.id
  database_edition = "ENTERPRISE_EDITION"
  availability_domain = data.oci_identity_availability_domain.ad1.name
  disk_redundancy = "NORMAL"
  shape = "VM.Standard2.2"
  ssh_public_keys = [var.publicRsaKey]
  display_name = "CDB"
  domain = "${oci_core_subnet.db.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com"
  hostname = "dbvm"
  data_storage_size_in_gb = "256"
  license_model = "LICENSE_INCLUDED"
  node_count = "1"
  fault_domains = ["FAULT-DOMAIN-1"]
  db_home {
    db_version = "19.0.0.0"
    display_name = "db-home"
    database {
      admin_password = random_password.database_admin_password.result
      db_name = "cdb"
      character_set = "AL32UTF8"
      ncharacter_set = "AL16UTF16"
      db_workload = "OLTP"
      pdb_name = var.dbName
    }
  }
  db_system_options {
          storage_management = "LVM"
  }
#  nsg_ids = ["${oci_core_network_security_group.test_network_security_group.id}"]
}
output "db_ocid" {
  value = oci_database_db_system.dbs.id
}

data "oci_database_db_homes" "db_homes" {
  compartment_id = var.compartment_ocid
  db_system_id   = oci_database_db_system.dbs.id
}

data "oci_database_databases" "databases" {
  compartment_id = var.compartment_ocid
  db_home_id     = data.oci_database_db_homes.db_homes.db_homes[0].db_home_id
}

data "oci_database_database" "db" {
    database_id = data.oci_database_databases.databases.databases[0].id
}

output "db_connection_string" {
  value = oci_database_database.db.connection_strings.cdb_default
}