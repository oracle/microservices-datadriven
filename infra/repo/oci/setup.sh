#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# INPUTS:
# input.env
# USER_OCID
# COMPARTMENT_OCID
# REGION
# REPO_NAME
# TOKEN_SECRET
#
# DOCKER_URL
# DOCKER_REGISTRY
#
# OUTPUTS:
# output.env
# DOCKER_REGISTRY

# Fail on error
set -e

# Check home is set
if test -z "$DCMS_HOME"; then
  echo "ERROR: This script requires DCMS_HOME environment variable to be set"
  exit
fi


STATE="$1"
if ! test -d "$STATE"; then
  echo "ERROR: State folder does not exist"
  exit
fi


NAMESPACE=`oci os ns get --compartment-id "$(state_get COMPARTMENT_OCID)" --query "data" --raw-output`
USER_NAME=`oci iam user get --user-id "$(state_get USER_OCID)" --query "data.name" --raw-output`


  RETRIES=0
  while test $RETRIES -le 30; do
    if echo "$(get_secret $TOKEN_SECRET)" | docker login -u "$NAMESPACE/$USER_NAME" --password-stdin "$REGION.ocir.io" &>/dev/null; then
      echo "Docker login completed"
      state_set DOCKER_REGISTRY "$(state_get REGION).ocir.io/$(state_get NAMESPACE)/$(state_get RUN_NAME)"
      export OCI_CLI_PROFILE=$(state_get REGION)
      break
    else
      # echo "Docker login failed.  Retrying"
      RETRIES=$((RETRIES+1))
      sleep 5
    fi
  done

  cat >$STATE/output.env <<!
  DOCKER_REGISTRY="${REGION}.ocir.io/$NAMESPACE/$REPO_NAME"