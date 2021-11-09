#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


IMAGE_NAME=inventory-micronaut
IMAGE_VERSION=0.1


if [ -z "$DOCKER_REGISTRY" ]; then
    echo "DOCKER_REGISTRY not set. Will get it with state_get"
  export DOCKER_REGISTRY=$(state_get DOCKER_REGISTRY)
fi

if [ -z "$DOCKER_REGISTRY" ]; then
    echo "Error: DOCKER_REGISTRY env variable needs to be set!"
    exit 1
fi


export IMAGE=${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_VERSION}

./gradlew build
./gradlew dockerFile
cd build/docker
echo IMAGE is $IMAGE
docker build -t $IMAGE .
#./gradlew dockerBuild
#./gradlew dockerPush
cd ../../

#gu install native-image
#./mvnw package -Dpackaging=native-image
#run with ./target/application

docker push $IMAGE
if [  $? -eq 0 ]; then
    docker rmi ${IMAGE}
fi