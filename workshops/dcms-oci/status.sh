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

echo "Build status:"
BUILDS="$LAB2_JAVA_BUILDS $LAB2_NON_JAVA_BUILDS $LAB3_JAVA_BUILDS $LAB3_NON_JAVA_BUILDS"
RUNNING_BUILDS=""
COMPLETED_BUILDS=""
FAILED_BUILDS=""
TO_BE_RUN_BUILDS=""
for b in $BUILDS; do
  if test -d $DCMS_BACKGROUND_BUILDS/$b; then
    if state_done "BUILD_$b"; then
      COMPLETED_BUILDS=" $b"
    else
      PID_FILE="$DCMS_BACKGROUND_BUILDS/$b/PID"
      if ! ps -fp $(<$PID_FILE) >>/dev/null 2>&1; then
        FAILED_BUILDS=" $b"
      else
        RUNNING_BUILDS=" $b"
      fi
    fi
  else
    TO_BE_RUN_BUILDS=" $b"
  fi
done

echo "Completed:      $COMPLETED_BUILDS"
echo "Running:        $RUNNING_BUILDS"
echo "Waiting to run: $TO_BE_RUN_BUILDS"
echo "Failed:         $FAILED_BUILDS"

for b in $FAILED_BUILDS; do
  echo "  Build $b log: $DCMS_LOG_DIR/build_$b.log"
done