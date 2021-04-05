#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Source the state functions
source $GRABDISH_HOME/utils/state_functions.sh

# Install Graal
while ! state_done "GRAAL_DONE"; do
  if ! test -d ~/graalvm-ce-java11-20.1.0; then
    curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-linux-amd64-20.1.0.tar.gz | tar xzf 
    mv graalvm-ce-java11-20.1.0 ~/
  fi
  state_set_done "GRAAL_DONE" 
done


# Install GraalVM native-image...
while ! state_done "GRAAL_IMAGE_DONE"; do
  ~/graalvm-ce-java11-20.1.0/bin/gu install native-image
  state_set_done "GRAAL_IMAGE_DONE" 
done


# Install the Soda jar
while ! state_done "SODA_DONE"; do
  cd $GRABDISH_HOME/lib
  mvn install:install-file -Dfile=orajsoda-1.1.0.jar -DgroupId=com.oracle \
    -DartifactId=orajsoda -Dversion=1.1.0 -Dpackaging=jar
  cd $GRABDISH_HOME/
  state_set_done "SODA_DONE" 
done


# Build all the images (no push) except frontend-helidon (requires Jaegar)
while ! state_done "BUILDS_DONE"; do
  BUILDS="admin-helidon order-helidon supplier-helidon-se inventory-helidon inventory-python inventory-nodejs inventory-helidon-se"
  for b in $BUILDS; do 
    cd $GRUBDASH_HOME/$b
    ./build.sh
  done
  state_set_done "BUILDS_DONE" 
done


# Build frontend-helidon (requires Jaegar)
while ! state_done "FRONTEND_BUILD_DONE"; do
  while ! state_done "JAEGAR_DONE"; do
    echo "Waiting got Jaegar"
    sleep 5
  done
  BUILDS="frontend-helidon"
  for b in $BUILDS; do 
    cd $GRUBDASH_HOME/$b
    ./build.sh
  done
  state_set_done "FRONTEND_BUILD_DONE" 
done


# Wait for docker login
while ! state_done "DOCKER_LOGIN_DONE"; do
  echo "Waiting for Docker Login"
  sleep 5
done


# Push all
while ! state_done "PUSH_DONE"; do
  BUILDS="frontend-helidon admin-helidon order-helidon supplier-helidon-se inventory-helidon inventory-python inventory-nodejs inventory-helidon-se"
  for b in $BUILDS; do 
    cd $GRUBDASH_HOME/$b
    ./push.sh
  done
  state_set_done "PUSH_DONE" 
done


# Build All Done
state_set_done "BUILD_ALL_DONE" 