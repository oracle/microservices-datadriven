#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

# Fail on error
set -e

SCRIPT_DIR=$(dirname $0)

IMAGE_NAME=frontend-helidon
IMAGE_VERSION=0.1

export DOCKER_REGISTRY=$(state_get DOCKER_REGISTRY)
export JAEGER_QUERY_ADDRESS=${state_get JAEGER_QUERY_ADDRESS}

if [ -z "DOCKER_REGISTRY" ]; then
    echo "Error: DOCKER_REGISTRY env variable needs to be set!"
    exit 1
fi

export IMAGE=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}
# this is not ideal but makes it convenient to access Jaeger UI from app page...
cp src/main/resources/web/index.html-template src/main/resources/web/index.html
sed -i "s|%JAEGER_QUERY_ADDRESS%|${JAEGER_QUERY_ADDRESS}|g" src/main/resources/web/index.html

mvn install
mvn package docker:build

if [ $DOCKERBUILD_RETCODE -ne 0 ]; then
    exit 1
fi
docker push $IMAGE
if [  $? -eq 0 ]; then
    docker rmi ${IMAGE}
fi
