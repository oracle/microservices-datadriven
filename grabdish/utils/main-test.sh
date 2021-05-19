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
export TEST_UI_PASSWORD='Welcome1;"#!:'
docker image prune -a -f
source setup.sh

if ! state_done SETUP_VERIFIED; do
  echo "SETUP failed"
  return 1
fi

# WALKTHROUGH
# Deploy the java services
./deploy.sh

# Get the frontend URL
RETRIES=0
while ! state_done FRONTEND_URL; do
  if IP=`services | awk '/frontend/ {print $5}'`; then
    RETRIES=(($RETRIES + 1))
    if test $RETRIES -gt 10; then
      exit
    sleep 5
  else
    state_set FRONTEND_URL "https://$IP"
  fi
done

sleep 70

# Is the UI available?
if wget -qO- --no-check-certificate --http-user grabdish --http-password Welcome1 "$FRONTEND_URL" | grep 'GrabDish Explorer' >/dev/null; then
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