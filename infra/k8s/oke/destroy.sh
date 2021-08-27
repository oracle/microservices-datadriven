#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   oci CLI (configured)
#   MSDD_CODE_HOME (set)
#   
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#
#   $1/input.env
#     
# OUTPUTS:
#   $1/output.env removed


# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit 1
fi


# Check home is set
if test -z "$MSDD_CODE_HOME"; then
  echo "ERROR: This script requires MSDD_CODE_HOME to be set"
  exit 1
fi
MY_CODE=$MSDD_CODE_HOME/infra/k8s/oke


# Check if we are already done
if ! test -f $MY_HOME/output.env; then
  exit 1
fi


cd $MY_HOME/terraform

# export TF_VAR_ociCompartmentOcid="$COMPARTMENT_OCID"
# export TF_VAR_ociRegionIdentifier="$REGION"
# export TF_VAR_ociTenancyOcid="$TENANCY_OCID"

if ! terraform init; then
    echo 'ERROR: terraform init failed!'
    exit 1
fi

if ! terraform destroy -auto-approve; then
    echo 'ERROR: terraform apply failed!'
    exit 1
fi


rm $MY_HOME/output.env