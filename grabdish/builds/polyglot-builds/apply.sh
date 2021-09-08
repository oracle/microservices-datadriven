#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


if ! provisioning-helper-pre-apply-sh; then
  exit 1
fi


cd $MY_CODE/../..
export GRABDISH_HOME=$PWD
export GRABDISH_LOG


# Build all the images
source $MY_CODE/../source.env
BUILDS="$POLYGLOT_BUILDS"
export JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH
export DOCKER_REGISTRY
for b in $BUILDS; do
  MS_CODE=$GRABDISH_HOME/$b
  echo "Building $MS_CODE"
  cd $MS_CODE
  # Run in parallel
  ./build.sh &>> $GRABDISH_LOG/build-$b.log &
done
wait


touch $OUTPUT_FILE