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
#
# OUTPUTS:
# output.env removed


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


# Run grabdish setup scripts
SCRIPTS="db k8s db-k8s"
for scr in $SCRIPTS; do
  SCRIPT_HOME=$MY_HOME/$scr
  mkdir -p $SCRIPT_HOME
  $GRABDISH_HOME/config/$scr/destroy.sh $SCRIPT_HOME
done


rm -f $MY_HOME/output.env