#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# Fail on error
set -e


# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID RUN_NAME DOCKER_REGISTRY JAVA_HOME IMAGE_REPOS'
while ! test -z "$DEPENDENCIES"; do
  echo "Waiting for $DEPENDENCIES"
  WAITING_FOR=""
  for d in $DEPENDENCIES; do
    if ! state_done $d; then
      WAITING_FOR="$WAITING_FOR $d"
    fi
  done
  DEPENDENCIES="$WAITING_FOR"
  sleep 1
done


# Set environment
export JAVA_HOME="$(state_get JAVA_HOME)"
export PATH=$JAVA_HOME/bin:$PATH
export DOCKER_REGISTRY="$(state_get DOCKER_REGISTRY)"


# Run base builds
if ! state_done BASE_BUILDS; then
  $MSDD_APPS_CODE/build-utils/base-builds.sh "$DCMS_LOG_DIR"
  state_set_done BASE_BUILDS
fi


# Run Polyglot builds
if ! state_done POLYGLOT_BUILDS; then
  $MSDD_APPS_CODE/build-utils/polyglot-builds.sh "$DCMS_LOG_DIR"
  state_set_done POLYGLOT_BUILDS
fi
