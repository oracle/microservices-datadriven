#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy-sh; then
  exit 1
fi


# Destroy polyglot builds
cd $DCMS_APP_STATE/config
provisioning-destroy

# Delete output
rm -f $OUTPUT_FILE
state_reset GRABDISH_THREAD