#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi


# Destroy app state
cd $DCMS_APP_STATE
provisioning-destroy


# Delete state file
rm -f $STATE_FILE
state_reset GRABDISH_THREAD