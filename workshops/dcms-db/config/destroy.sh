#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-destroy; then
  exit 1
fi

cd $MY_STATE/terraform

# Workaround for issue where terraform fails in OCI cloud shell after a few days
rm -rf .terraform
rm -f .terraform.lock.hcl

# Start the provisioning destroy
source terraform-env.sh

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit 1
fi

if ! terraform destroy -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit 1
fi

rm -f $STATE_FILE
