#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

if ! provisioning-helper-pre-apply; then
  exit 1
fi


if ! test -d $MY_STATE/terraform; then
  rm -rf $MY_STATE/terraform
  cp -r $DCMS_CICD_JNKNS_DIR $MY_STATE
fi


# Start the provisioning apply
cd $MY_STATE/terraform
source $DCMS_CICD_JNKNS_DIR/terraform-env.sh

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit 1
fi

if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit 1
fi

state_set JENKINS_IP `terraform output jenkins_public_ip`
set_secret JENKINS_PRIVATE_KEY `terraform output -raw generated_ssh_private_key`

# Write the output
cat >$OUTPUT_FILE <<!

!