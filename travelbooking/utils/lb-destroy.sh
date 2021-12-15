#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Delete LBs
echo "Deleting Load Balancers"
LBIDS=`oci lb load-balancer list --compartment-id "$(state_get COMPARTMENT_OCID)" --query "join(' ',data[*].id)" --raw-output`
for lb in $LBIDS; do
  oci lb load-balancer delete --load-balancer-id "$lb" --force
done