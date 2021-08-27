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
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit 1
fi


# Check home is set
if test -z "$GRABDISH_LOG"; then
  echo "ERROR: This script requires GRABDISH_LOG to be set"
  exit 1
fi


# Delete Images
echo "Deleting Images"
IIDS=`oci artifacts container image list --compartment-id "$COMPARTMENT_OCID" --query "join(' ',data.items[*].id)" --raw-output`
for i in $IIDS; do
  oci artifacts container image delete --image-id "$i" --force
done

# Delete Repos
echo "Deleting Repositories"
REPO_IDS=`oci artifacts container repository list --compartment-id "$COMPARTMENT_OCID" --query "join(' ', data.items[*].id)" --raw-output`
for r in $REPO_IDS; do 
  oci artifacts container repository delete --repository-id "$r" --force
done


# rm -rf ~/graalvm-ce-java11-20.1.0


rm $MY_HOME/output.env