#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# INPUTS:
#
#
# OUTPUTS:
# output.env removed

# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit 1
fi


# Check code home is set
if test -z "$MSDD_CODE_HOME"; then
  echo "ERROR: This script requires MSDD_CODE_HOME to be set"
  exit 1
fi
MY_CODE=$MSDD_CODE_HOME/infra/db/atp


# Check if we are already done
if ! test -f $MY_HOME/output.env; then
  exit
fi


# Execute terraform
cd $MY_HOME/terraform
source $MY_HOME/state.env

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit 1
fi

if ! terraform destroy -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit 1
fi


rm $MY_HOME/output.env