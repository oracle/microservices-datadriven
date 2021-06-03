#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


IMAGE_NAME=inventory-postgres-kafka
IMAGE_VERSION=0.1

export DOCKER_REGISTRY=$(state_get DOCKER_REGISTRY)

if [ -z "$DOCKER_REGISTRY" ]; then
    echo "Error: DOCKER_REGISTRY env variable needs to be set!"
    exit 1
fi

export IMAGE=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}

# mvn install
# mvn package docker:build
mvn package

docker push $IMAGE
if [  $? -eq 0 ]; then
    docker rmi ${IMAGE}
fi