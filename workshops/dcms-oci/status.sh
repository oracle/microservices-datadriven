#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Make sure this is run via source or .
if (return 0 2>/dev/null); then
  echo "ERROR: Usage './status.sh'"
  exit 1
fi

# Environment must be setup before running this script
if test -z "$DCMS_STATE"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# First parameter repeat
if test "${1-0}" != '0'; then
  # Repeating so make some screen space
  for i in {1..15}; do
    echo
  done

  for i in {1..15}; do
    tput cuu1
  done
fi

# Remember initial screen location
tput sc

while true; do
  # Move to initial screen position and clear to bottom of screen
  tput rc
  tput ed

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
    applying)
      PHASE='SETUP RUNNING'
      ;;
    applying-failed)
      PHASE='SETUP FAILED'
      ;;
    applied)
      PHASE='SETUP COMPLETED'
      ;;
    destroying)
      PHASE='TEARDOWN RUNNING'
      ;;
    destroying-failed)
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
  printf 'dcms-oci workshop provisioning phase: '
  tput bold
  echo "$PHASE"
  tput sgr0
  echo

  $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/config/status.sh

  if [[ "$PHASE" =~ SETUP* ]]; then
    echo
    for lab in $LABS_WITH_BUILDS; do
      $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/background-build-status.sh "$lab"
    done
  fi

  # clear to bottom of screen
  tput ed

  # First parameter repeat
  if test "${1-0}" == '0'; then
    # No repeat
    break
  fi

  if [[ ! "$PHASE" =~ .*RUNNING ]]; then
    # Nothing more to see
    break
  fi

  sleep "${1-10}"
done

exit 0