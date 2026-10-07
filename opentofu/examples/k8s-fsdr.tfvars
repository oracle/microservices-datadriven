# Copyright (c) 2024, 2026, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

region          = "uk-london-1"
label_prefix    = "obaasdr"
fsdr_enabled    = true
fsdr_region_1   = "uk-cardiff-1"
fsdr_plan_types = ["SWITCHOVER", "FAILOVER", "START_DRILL", "STOP_DRILL"]
fsdr_timeouts = {
  create = "40m"
  update = "40m"
  delete = "40m"
}

# Increment after protection group changes.
fsdr_plan_refresh_trigger = 0
fsdr_plan_verify_trigger  = 0

# Enable after preparing Resource Principal IAM policies.
# fsdr_automatic_dr = {
#   is_auto_switchover_enabled = true
#   is_auto_failover_enabled   = true
# }

# Applying this entry submits a precheck.
# fsdr_plan_executions = {
#   switchover = { plan_execution_type = "SWITCHOVER_PRECHECK" }
# }
