#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy-sh; then
  exit 1
fi


cd $MY_CODE/..
export GRABDISH_HOME=$PWD


# Run grabdish destroy for each config in order
CONFIGS="db-k8s k8s db"
for c in $SCRIPTS; do
  CONFIG_STATE=$MY_STATE/$c
  cd $CONFIG_STATE
  provisioning-destroy
done


rm -f $MY_HOME/output.env