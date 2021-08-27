#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Dependencies:
#   kubectl
#   
# INPUTS:
#   Parameters:
#     $1  Home directory (to store state, inputs and outputs)
#   <none>
#
# OUTPUTS:
#   output.env removed

exit # for now
# Fail on error
set -e


# Check the home folder
MY_HOME="$1"
if ! test -d "$MY_HOME"; then
  echo "ERROR: The home folder does not exist"
  exit
fi


# Delete OKE Namespace
kubectl delete ns msdataworkshop


# Delete SSL Certs and anything else
rm -rf $MY_HOME/*