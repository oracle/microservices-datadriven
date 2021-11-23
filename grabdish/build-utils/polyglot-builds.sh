#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# $1: Log directory to place individual logs
#
# Requires exported JAVA_HOME and DOCKER_REGISTRY variables, and JAVA_HOME/bin on the path.


# Fail on error
set -e


GRABDISH_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"


if test -z "$1"; then
  echo "ERROR: no log directory specified"
fi
LOG_DIR="$1"


if ! test -d $LOG_DIR; then
  echo "ERROR: Log directory $LOG_DIR does not exits"
fi


# Build all the images
source $GRABDISH_HOME/build-utils/source.env
BUILDS="$POLYGLOT_BUILDS"
for b in $BUILDS; do
  MS_CODE=$GRABDISH_HOME/$b
  echo "Building $MS_CODE"
  cd $MS_CODE
  # Tried running in parallel and found to be unstable, so run serially.  Assume maven thread safety issue.
  ./build.sh > $LOG_DIR/build-$b.log 2>&1 &
done

wait