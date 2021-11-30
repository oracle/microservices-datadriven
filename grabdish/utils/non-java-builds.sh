#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

P2_BUILDS="foodwinepairing-python"
P3_NON_JAVA_BUILDS="inventory-python inventory-nodejs inventory-dotnet inventory-go"
# Run serially (Java)
P3_JAVA_BUILDS="inventory-helidon-se order-mongodb-kafka inventory-postgres-kafka"
# Run serially (Java)
P4_NON_JAVA_BUILDS=""
P4_JAVA_BUILDS="inventory-springboot inventory-micronaut inventory-quarkus"
# we provision a repos for db-log-exporter but it's in nested observability/db-log-exporter dir so not reusing BUILDS list to build (see DB_LOG_EXPORTER_BUILD below)

REPOS="inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-helidon-se order-mongodb-kafka inventory-postgres-kafka inventory-springboot inventory-micronaut inventory-micronaut-native-image inventory-quarkus db-log-exporter foodwinepairing-python"

# Provision Repos
while ! state_done NON_JAVA_REPOS; do
  for b in $REPOS; do
    oci artifacts container repository create --compartment-id "$(state_get COMPARTMENT_OCID)" --display-name "$(state_get RUN_NAME)/$b" --is-public true
  done
  state_set_done NON_JAVA_REPOS
done


# Wait for docker login
while ! state_done DOCKER_REGISTRY; do
  echo "Waiting for Docker Registry"
  sleep 5
done


# Wait for java builds
while ! state_done JAVA_BUILDS; do
  echo "Waiting for Java Builds"
  sleep 10
done


# Build P2_BUILDS images
while ! state_done P2_BUILDS; do
  for b in $P2_BUILDS; do
    cd $GRABDISH_HOME/$b
    echo "### building $b"
    time ./build.sh &>> $GRABDISH_LOG/build-$b.log
  done
  wait
  state_set_done P2_BUILDS
done

# Build P3_BUILDS images
while ! state_done P3_BUILDS; do
  for b in $P3_NON_JAVA_BUILDS; do
    cd $GRABDISH_HOME/$b
    echo "### building $b"
    time ./build.sh &>> $GRABDISH_LOG/build-$b.log &
  done

  # Run serially because maven is unstable in parallel
  for b in $P3_JAVA_BUILDS; do
    cd $GRABDISH_HOME/$b
    echo "### building $b"
    time ./build.sh &>> $GRABDISH_LOG/build-$b.log
  done
  wait
  state_set_done P3_BUILDS
done

if ! state_done NON_JAVA_BUILDS; then
  state_set_done NON_JAVA_BUILDS
fi


# Build P4_BUILDS images
while ! state_done P4_BUILDS; do
  for b in $P4_NON_JAVA_BUILDS; do
    cd $GRABDISH_HOME/$b
    echo "### building $b"
    time ./build.sh &>> $GRABDISH_LOG/build-$b.log &
  done

  # Run serially because maven is unstable in parallel
  for b in $P4_JAVA_BUILDS; do
    cd $GRABDISH_HOME/$b
    echo "### building $b"
    time ./build.sh &>> $GRABDISH_LOG/build-$b.log
  done
  wait
  state_set_done P4_BUILDS
done


# Build the db-log-exporter image
while ! state_done DB_LOG_EXPORTER_BUILD; do
  cd $GRABDISH_HOME/observability/db-log-exporter
  echo "### building db-log-exporter"
  time ./build.sh &>> $GRABDISH_LOG/build-db-log-exporter.log &
  state_set_done DB_LOG_EXPORTER_BUILD
done
