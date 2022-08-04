#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

IMAGE_NAME=oracle-developers-okafka-producer
IMAGE_VERSION=0.0.1-SNAPSHOT
#IMAGE_NAME=$1
#IMAGE_VERSION=$2

# Check home is set
if test -z "$LAB_HOME"; then
  echo "ERROR: This script requires LAB_HOME to be set"
  exit
fi

# Check if wallet.zip does Not Exist
if [ ! -f "$LAB_HOME/wallet/wallet.zip" ]; then
  echo "ERROR: The wallet.zip should be in $LAB_HOME/wallet"
  exit
fi

#if [ -z "$CONTAINER_REGISTRY" ]; then
#    echo "CONTAINER_REGISTRY not set. Will get it with state_get"
#  export CONTAINER_REGISTRY=$(state_get CONTAINER_REGISTRY)
#fi

#if [ -z "$CONTAINER_REGISTRY" ]; then
#    echo "Error: CONTAINER_REGISTRY env variable needs to be set!"
#    exit 1
#fi

# Copy wallet to app context
mkdir ./wallet
cp "$LAB_HOME"/wallet/* ./wallet/

#export IMAGE="${CONTAINER_REGISTRY}"/"${IMAGE_NAME}":"${IMAGE_VERSION}"
export IMAGE="${IMAGE_NAME}":"${IMAGE_VERSION}"

# Build App Container Image
docker build . -t "$IMAGE" \
            --build-arg IMAGE_NAME="${IMAGE_NAME}" \
            --build-arg IMAGE_VERSION="${IMAGE_VERSION}"

# Cleanup wallet on app context
rm -rf ./wallet

# Push App Container Image to Image Repository
#docker push "$IMAGE"

# Cleanup local docker
#if [  $? -eq 0 ]; then
#    docker rmi "${IMAGE}"
#fi