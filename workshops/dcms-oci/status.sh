#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if (return 0 2>/dev/null); then
  echo "ERROR: Usage './status.sh'"
  exit
fi

# Environment must be setup before running this script
if test -z "$DCMS_STATE"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# Banner
echo
echo "$DCMS_WORKSHOP workshop provisioning status:"
echo

# Code and state location
echo "Workshop installed at $MSDD_CODE"
echo

# Get the setup status
if ! DCMS_STATUS=$(provisioning-get-status $DCMS_STATE); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

# Provisioning status
echo "Overall provisioning status: $DCMS_STATUS"

$MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config/status.sh

for l in Lab2 Lab3; do
  $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/background-build-status.sh "$l"
done