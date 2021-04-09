#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


IMAGE_NAME=inventory-dotnet
IMAGE_VERSION=latest
#IMAGE_VERSION=0.1

if [ -z "DOCKER_REGISTRY" ]; then
    echo "Error: DOCKER_REGISTRY env variable needs to be set!"
    exit 1
fi

export IMAGE=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}

docker build -t inventory-dotnet .

if [ $DOCKERBUILD_RETCODE -ne 0 ]; then
    exit 1
fi
docker push $IMAGE
if [  $? -eq 0 ]; then
    docker rmi ${IMAGE}
fi