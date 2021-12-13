#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -eu


MY_STATE=$PWD

# Wait for dependencies
DEPENDENCIES='DOCKER_REGISTRY JAVA_HOME IMAGE_REPOS'
while ! test -z "$DEPENDENCIES"; do
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if ! state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  echo "Waiting for $DEPENDENCIES"
  sleep 1
done

# Set environment
export JAVA_HOME="$(state_get JAVA_HOME)"
export PATH=$JAVA_HOME/bin:$PATH
export DOCKER_REGISTRY="$(state_get DOCKER_REGISTRY)"

for lab in $LABS_WITH_BUILDS; do
  
  lab_upper=`echo $lab | tr '[:lower:]' '[:upper:]'`

  JAVA_BUILDS_VAR="${lab_upper}_JAVA_BUILDS"
  NON_JAVA_BUILDS_VAR="${lab_upper}_NON_JAVA_BUILDS"

  # Run builds
  for b in ${!NON_JAVA_BUILDS_VAR}; do
    mkdir -p $MY_STATE/$b
    cd $MY_STATE/$b
    # Run non-java in parallel
    $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/background-build-runner.sh "$b" >>$DCMS_LOG_DIR/build_$b.log 2>&1 &
  done

  for b in ${!JAVA_BUILDS_VAR}; do
    mkdir -p $MY_STATE/$b
    cd $MY_STATE/$b
    # Run java serially
    $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/background-build-runner.sh "$b" >>$DCMS_LOG_DIR/build_$b.log 2>&1
  done

  # Wait for Lab builds
  wait
done