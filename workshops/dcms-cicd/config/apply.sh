#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu

if ! provisioning-helper-pre-apply; then
  exit 1
fi

rm -rf $MY_STATE/jenkins
cp -r $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config/jenkins $MY_STATE

# Start the provisioning destroy
cd $MY_STATE/jenkins
source scripts/terraform-env.sh

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit 1
fi

if ! terraform apply -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit 1
fi