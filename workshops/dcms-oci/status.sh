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

# Get the setup status
if ! DCMS_STATUS=$(provisioning-get-status $DCMS_STATE); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

RETURN_CODE=0 # Not running
case "$DCMS_STATUS" in
  new)
    PHASE='NEW (ready for setup)'
    ;;
  apply)
    PHASE='SETUP RUNNING'
    RETURN_CODE=1
    ;;
  apply-failed)
    PHASE='SETUP FAILED'
    ;;
  applied)
    PHASE='SETUP COMPLETED'
    ;;
  destroy)
    PHASE='TEARDOWN RUNNING'
    RETURN_CODE=1
    ;;
  destroy-failed)
    PHASE='TEARDOWN FAILED'
    ;;
  destroyed)
    PHASE='TEARDOWN COMPLETED'
    ;;
  byo)
    PHASE='BYO'
  ;;
esac

# Provisioning status
echo
echo "dcms-oci workshop provisioning phase: $PHASE"
echo

$MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config/status.sh

for lab in $LABS_WITH_BUILDS; do
  $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/background-build-status.sh "$lab"
done

return $RETURN_CODE