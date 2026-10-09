# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

resource "local_file" "fsdr_recovery_config" {
  content         = jsonencode(local.fsdr_recovery_config)
  filename        = "${path.root}/cfgmgt/stage/fsdr/config.json"
  file_permission = "0600"
}

resource "terraform_data" "fsdr_bootstrap" {
  triggers_replace = [timestamp()]
  provisioner "local-exec" {
    command = "python3 ${path.root}/cfgmgt/recovery/bootstrap.py --config ${local_file.fsdr_recovery_config.filename} bootstrap"
  }
  depends_on = [oci_identity_policy.fsdr, oci_identity_policy.fsdr_container]
}

resource "terraform_data" "fsdr_members" {
  triggers_replace = [terraform_data.fsdr_bootstrap.id]
  provisioner "local-exec" {
    command = "python3 ${path.root}/cfgmgt/recovery/bootstrap.py --config ${local_file.fsdr_recovery_config.filename} enroll"
  }
  depends_on = [terraform_data.fsdr_bootstrap]
}

resource "terraform_data" "fsdr_prepare" {
  triggers_replace = [terraform_data.fsdr_members.id, module.fsdr_region_1.dr_plan_ids, var.plan_refresh_trigger, var.plan_verify_trigger]
  provisioner "local-exec" {
    command = "python3 ${path.root}/cfgmgt/recovery/bootstrap.py --config ${local_file.fsdr_recovery_config.filename} prepare"
  }
  depends_on = [terraform_data.fsdr_bootstrap]
}
