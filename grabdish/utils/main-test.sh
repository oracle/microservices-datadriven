#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Check home is set
if test -z "$GRABDISH_HOME"; then
  echo "ERROR: This script requires GRABDISH_HOME to be set"
  exit
fi


# SETUP
export TEST_DB_PASSWORD='Welcome12345;#!:'
# export TEST_UI_PASSWORD='Welcome1;"#!:'
export TEST_UI_PASSWORD='Welcome1'
if ! state_done SETUP_VERIFIED; then
  docker image prune -a -f
  source setup.sh
fi

if ! state_done SETUP_VERIFIED; then
  echo "SETUP failed"
  return 1
fi

# WALKTHROUGH
# Deploy the java services
./deploy.sh

sleep 60

# Get the frontend URL
RETRIES=0
while ! state_done FRONTEND_URL; do
  if IP=`kubectl get services -n msdataworkshop | awk '/frontend/ {print $4}'`; then
    state_set FRONTEND_URL "https://$IP"
  else
    RETRIES=$(($RETRIES + 1))
    if test $RETRIES -gt 10; then
      echo "ERROR: Failed to get FRONTEND_URL"
      exit
    fi
    sleep 5
  fi
done

# Is the UI available?
if wget -qO- --no-check-certificate --http-user grabdish --http-password "$TEST_UI_PASSWORD" "$(state_get FRONTEND_URL)" | grep 'GrabDish Explorer' >/dev/null; then
  echo "ERROR: UI Unavailable"
fi

# Functional test on order 66/67
utils/func-test.sh 66


# POLYGLOT
# Deploy each inventory service and perform functional test
utils/polyglot-test.sh


# SCALING
# utils/scaling-test.sh


# TRACING
# TODO

# APEX
# TODO


# TEARDOWN
source destroy.sh