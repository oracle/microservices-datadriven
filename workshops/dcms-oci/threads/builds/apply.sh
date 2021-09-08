#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply-sh; then
  exit 1
fi


if state_done BUILDS_THREAD; then
  exit
fi


# Install GtaalVM
STATE=$DCMS_INFRA_STATE/java
mkdir -p $STATE
cd $STATE
provisioning-apply $MSDD_INFRA_CODE/java/GraalVM
(
  source $STATE/output.env
  state_set JAVA_HOME $JAVA_HOME
)

# Wait for dependencies
DEPENDENCIES='COMPARTMENT_OCID RUN_NAME'
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


# Create Image Repos
STATE=$DCMS_INFRA_STATE/image-repo
mkdir -p $STATE
# Get build names
source $MSDD_APPS_CODE/$DCMS_APP/builds/source.env
cat >$STATE/input.env <<!
COMPARTMENT_OCID=$(state_get COMPARTMENT_OCID)
RUN_NAME=$(state_get RUN_NAME)
BUILDS='$BASE_BUILDS $POLYGLOT_BUILDS'
!
cd $STATE
provisioning-apply $MSDD_INFRA_CODE/image-repo/ocr
state_set_done IMAGE_REPOS


# Wait for deoendencies
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


# Run base builds
STATE=$DCMS_APP_STATE/builds/base_builds
mkdir -p $STATE
cat >$STATE/input.env <<!
GRABDISH_LOG=$DCMS_LOG_DIR
JAVA_HOME=$(state_get JAVA_HOME)
DOCKER_REGISTRY='$(state_get DOCKER_REGISTRY)'
!
cd $STATE
provisioning-apply $MSDD_APPS_CODE/$DCMS_APP/builds/base-builds
state_set_done BASE_BUILDS


# Run polyglot builds
STATE=$DCMS_APP_STATE/builds/polyglot_builds
mkdir -p $STATE
cat >$STATE/input.env <<!
GRABDISH_LOG=$DCMS_LOG_DIR
JAVA_HOME=$(state_get JAVA_HOME)
DOCKER_REGISTRY='$(state_get DOCKER_REGISTRY)'
!
cd $STATE
provisioning-apply $MSDD_APPS_CODE/$DCMS_APP/builds/polyglot-builds
state_set_done POLYGLOT_BUILDS


touch $OUTPUT_FILE
state_set_done BUILDS_THREAD