#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -e


if test -z "$1"; then
  echo "ERROR: Usage background-builds.sh <STATE FOLDER>"
  exit
fi


# Prevent parallel execution
PID_FILE="$1/PID"
if test -f $PID_FILE && ps -fp $(<$PID_FILE); then
    echo "A script is already running against ${MY_STATE}."
    echo "If you want to run an operation on it, kill process $(cat $PID_FILE), delete the file $PID_FILE, and then retry"
    exit
fi
trap "rm -f -- '$PID_FILE'" EXIT
echo $$ > "$PID_FILE"


# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID RUN_NAME DOCKER_REGISTRY JAVA_HOME IMAGE_REPOS'
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


# Run base builds
if ! state_done BASE_BUILDS; then
  $MSDD_APPS_CODE/$DCMS_APP/build-utils/base-builds.sh "$DCMS_LOG_DIR"
  state_set_done BASE_BUILDS
  state_set_done JAVA_BUILDS # Legacy
fi


# Run Polyglot builds
if ! state_done POLYGLOT_BUILDS; then
  $MSDD_APPS_CODE/$DCMS_APP/build-utils/polyglot-builds.sh "$DCMS_LOG_DIR"
  state_set_done POLYGLOT_BUILDS
  state_set_done NON_JAVA_BUILDS # Legacy
fi
