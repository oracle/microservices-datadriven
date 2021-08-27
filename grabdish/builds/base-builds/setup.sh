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
#   $1/input.env
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
  exit 1
fi


# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit 1
fi


# Check home is set
if test -z "$GRABDISH_LOG"; then
  echo "ERROR: This script requires GRABDISH_LOG to be set"
  exit 1
fi


# Check if we are already done
if test -f $MY_HOME/output.env; then
  exit 1
fi


# Source input.env
if test -f $MY_HOME/input.env; then
  source "$MY_HOME"/input.env
else
  echo "ERROR: input.env is required"
  exit 1
fi


BUILDS="frontend-helidon order-helidon supplier-helidon-se inventory-helidon"


# Provision Repos
for b in $BUILDS; do
  oci artifacts container repository create --compartment-id "$COMPARTMENT_OCID" --display-name "$RUN_NAME/$b" --is-public true
done


# Install Graal
if ! test -d ~/graalvm-ce-java11-20.1.0; then
  cd $MY_HOME
  curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-linux-amd64-20.1.0.tar.gz | tar xz
  mv graalvm-ce-java11-20.1.0 ~/
  ~/graalvm-ce-java11-20.1.0/bin/gu install native-image
fi


# Build all the images
for b in $BUILDS; do
  echo "$GRABDISH_HOME/$b $GRABDISH_LOG/build-$b.log"
  cd $GRABDISH_HOME/$b
  time ./build.sh &>> $GRABDISH_LOG/build-$b.log
done


touch $MY_HOME/output.env