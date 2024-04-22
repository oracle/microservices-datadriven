#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


BUILDS="frontend-helidon order-helidon supplier-helidon-se inventory-helidon"

# Provision Repos
while ! state_done JAVA_REPOS; do
  for b in $BUILDS; do
    oci artifacts container repository create --compartment-id "$(state_get COMPARTMENT_OCID)" --display-name "$(state_get RUN_NAME)/$b" --is-public true
  done
  state_set_done JAVA_REPOS
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


# Wait for docker login
while ! state_done DOCKER_REGISTRY; do
  echo "Waiting for Docker Registry"
  sleep 5
done


# Build all the images (no push) except frontend-helidon (requires Jaeger)
while ! state_done JAVA_BUILDS; do
  for b in $BUILDS; do
    cd $GRABDISH_HOME/$b
    echo "### building $b"
    time ./build.sh &>> $GRABDISH_LOG/build-$b.log
  done
  state_set_done JAVA_BUILDS
done