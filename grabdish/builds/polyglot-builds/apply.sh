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
source $MY_CODE/../builds.env
BUILDS="$POLYGLOT_BUILDS"
export PATH=$JAVA_HOME/bin:$PATH
export DOCKER_REGISTRY
for b in $BUILDS; do
  cd $GRABDISH_HOME/$b
  # Run in parallel
  ./build.sh &>> $GRABDISH_LOG/build-$b.log &
done
wait


touch $MY_HOME/output.env