#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Fail on error
set -eu

# Local Run Only
#image: ghcr.io/pasimoes/order-in-store-service:1.0
#CONTAINER_REGISTRY=ghcr.io/pasimoes

IMAGE_NAME=oracle-developers-kafka-consumer
IMAGE_VERSION=0.0.1-SNAPSHOT
#IMAGE_NAME=$1
#IMAGE_VERSION=$2

# Check home is set
#if test -z "$LAB_HOME"; then
#  echo "ERROR: This script requires LAB_HOME to be set"
#  exit
#fi

#if [ -z "$CONTAINER_REGISTRY" ]; then
#    echo "CONTAINER_REGISTRY not set. Will get it with state_get"
#  export CONTAINER_REGISTRY=$(state_get CONTAINER_REGISTRY)
#fi

#if [ -z "$CONTAINER_REGISTRY" ]; then
#    echo "Error: CONTAINER_REGISTRY env variable needs to be set!"
#    exit 1
#fi

#export IMAGE="${CONTAINER_REGISTRY}"/"${IMAGE_NAME}":"${IMAGE_VERSION}"
export IMAGE="${IMAGE_NAME}":"${IMAGE_VERSION}"

# Build the project
# mvn clean install -DskipTests

# Build App Container Image
docker build . -t "$IMAGE" \
            --build-arg IMAGE_NAME="${IMAGE_NAME}" \
            --build-arg IMAGE_VERSION="${IMAGE_VERSION}"

# Push App Container Image to Image Repository
#docker push "$IMAGE"

# Cleanup local docker
#if [  $? -eq 0 ]; then
#    docker rmi "${IMAGE}"
#fi


# Print the maven build summary

# Print deployment result
result=$(grep "writing image" "$LAB_LOG"/kafka-consumer-deployment.log)
if [[ "$result" =~ *"writing"* ]]; then
  echo "ERROR: Kafka consumer microservices deployment failed!"
  exit
else
  PRINT_VAR="Kafka consumer microservices deployment succeeded!"
  PRINT_VAR="$PRINT_VAR\n"$(grep -hr -A3 "writing image" "$LAB_LOG"/kafka-consumer-deployment.log)
  echo "$PRINT_VAR"
  state_set_done KAFKA_CONSUMER_MS_DEPLOYED
fi