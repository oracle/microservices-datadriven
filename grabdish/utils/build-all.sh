#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Provision Repos
while ! state_done REPOS; do
  BUILDS="frontend-helidon admin-helidon order-helidon supplier-helidon-se inventory-helidon inventory-python inventory-nodejs inventory-helidon-se"
  for b in $BUILDS; do 
    oci artifacts container repository create --compartment-id "$(state_get COMPARTMENT_OCID)" --display-name "$(state_get RUN_NAME)/$b" --is-public true
  done
  state_set_done REPOS
done


# Install Graal
while ! state_done GRAAL; do
  if ! test -d ~/graalvm-ce-java11-20.1.0; then
    curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-linux-amd64-20.1.0.tar.gz | tar xz
    mv graalvm-ce-java11-20.1.0 ~/
  fi
  state_set_done GRAAL
done


# Install GraalVM native-image...
while ! state_done GRAAL_IMAGE; do
  ~/graalvm-ce-java11-20.1.0/bin/gu install native-image
  state_set_done GRAAL_IMAGE
done


# Install the Soda jar
while ! state_done SODA; do
  cd $GRABDISH_HOME/lib
  mvn install:install-file -Dfile=orajsoda-1.1.0.jar -DgroupId=com.oracle \
    -DartifactId=orajsoda -Dversion=1.1.0 -Dpackaging=jar
  cd $GRABDISH_HOME/
  state_set_done SODA
done


# Wait for docker login
while ! state_done DOCKER_REGISTRY; do
  echo "Waiting for Docker Registry"
  sleep 5
done


## Run the java-builds.sh in the background
if ! state_get JAVA_BUILDS; then
  if ps -ef | grep "$GRABDISH_HOME/utils/java-builds.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/java-builds.sh is already running"
  else
    echo "Executing java-builds.sh in the background"
    nohup $GRABDISH_HOME/utils/java-builds.sh &>> $GRABDISH_LOG/java-builds.log &
  fi
fi


# Run the non-java-builds.sh in the background
if ! state_get NON_JAVA_BUILDS; then
  if ps -ef | grep "$GRABDISH_HOME/utils/non-java-builds.sh" | grep -v grep; then
    echo "$GRABDISH_HOME/utils/non-java-builds.sh is already running"
  else
    echo "Executing non-java-builds.sh in the background"
    nohup $GRABDISH_HOME/utils/non-java-builds.sh &>> $GRABDISH_LOG/non-java-builds.log &
  fi
fi


# Build frontend-helidon (requires Jaeger)
while ! state_done FRONTEND_BUILD; do
  while ! state_done JAEGER_QUERY_ADDRESS; do
    echo "Waiting for JAEGER_QUERY_ADDRESS"
    sleep 5
  done
  export 
  BUILDS="frontend-helidon"
  for b in $BUILDS; do 
    cd $GRABDISH_HOME/$b
    ./build.sh
  done
  state_set_done FRONTEND_BUILD
done


# Push all
#while ! state_done "PUSH"; do
#  BUILDS="frontend-helidon admin-helidon order-helidon supplier-helidon-se inventory-helidon inventory-python inventory-nodejs inventory-helidon-se"
#  for b in $BUILDS; do 
#    cd $GRUBDASH_HOME/$b
#   ./push.sh
#  done
#  state_set_done "PUSH" 
#done


# Build All Done
state_set_done BUILD_ALL