#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   docker (logged in)
#   oci CLI (configured)
#   GRABDISH_HOME (set)
#   GRABDISH_LOG (set)
#   
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#
#   $1/input.env or in environment
#     COMPARTMENT_OCID
#     RUN_NAME
#     DOCKER_REGISTRY
#     
# OUTPUTS:
#   $1/output.env (empty to signify done)


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
if test -f $MY_HOME/output.env; then
  source "$MY_HOME"/input.env
else
  echo "ERROR: input.env is required"
  exit
fi


BUILDS="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se order-mongodb-kafka inventory-postgres-kafka inventory-springboot"


# Provision Repos
for b in $BUILDS; do
  oci artifacts container repository create --compartment-id "$COMPARTMENT_OCID" --display-name "$RUN_NAME/$b" --is-public true
done


# Build all the images
for b in $BUILDS; do
  cd $GRABDISH_HOME/$b
  time ./build.sh &>> $GRABDISH_LOG/build-$b.log &
done
wait


touch $MY_HOME/output.env