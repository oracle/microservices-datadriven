# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  adb_ocid = oci_database_autonomous_database.autonomous_database.id
  ci_pubip = oci_core_instance.instance.public_ip
}
