#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   OCI CLI (configured)
#   sqlplus
#   kubectl (configured)
#   GRABDISH_HOME (set)
#   GRABDISH_LOG (set)
#
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#
#   input.env
#     COMPARTMENT_OCID
#     ORDERDB_TNS_ADMIN
#     ORDERDB_ALIAS
#     INVENTORYDB_ALIAS
#     REGION
#     RUN_NAME
#     DOCKER_REGISTRY
#
# OUTPUTS:
# output.env
#   <empty indicates done>


# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit
fi


# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit
fi


# Check home is set
if test -z "$GRABDISH_LOG"; then
  echo "ERROR: This script requires GRABDISH_LOG to be set"
  exit
fi


# Check if we are already done
if test -f $MY_HOME/output.env; then
  exit
fi


# Source input.env
if test -f $MY_HOME/input.env; then
  source "$MY_HOME"/input.env
else
  echo "ERROR: input.env is required"
  exit
fi


# Run grabdish setup scripts
SCRIPTS="db k8s db-k8s"
for scr in $SCRIPTS; do
  SCRIPT_HOME=$MY_HOME/$scr
  mkdir -p $SCRIPT_HOME
  cat >$SCRIPT_HOME/input.env <<!
COMPARTMENT_OCID='$COMPARTMENT_OCID'
ORDERDB_TNS_ADMIN='$ORDERDB_TNS_ADMIN'
ORDERDB_ALIAS='$ORDERDB_ALIAS'
INVENTORYDB_ALIAS='$INVENTORYDB_ALIAS'
REGION='$REGION'
RUN_NAME='$RUN_NAME'
DOCKER_REGISTRY='$DOCKER_REGISTRY'
!
  $GRABDISH_HOME/utils/$scr-setup.sh $SCRIPT_HOME
done


touch $MY_HOME/output.env