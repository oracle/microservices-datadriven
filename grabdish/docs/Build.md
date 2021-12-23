_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Grabdish Build Process

It is necessary to build the grabdish microservices before they can be deployed.  Each microservice has its own build script.  A build script compiles the code, constructs a docker image, and pushes the image to the repository.  The image is used when deploying the microservice.  It is possible to run the builds and provisioning in parallel to save time, however, building more than one java based microservice in parallel has been found to be unreliable and so is not recommended.

## Prerequisites

The following are required before building a Grabdish microservice:

1. Java installed
2. Docker installed
3. Docker image repository prepared
4. Software cloned

## Environment Variables

To build grabdish services the following environment variables must be exported:

DOCKER_REGISTRY
JAVA_HOME
PATH=${JAVA_HOME}/bin:$PATH

## Steps

1. Change to a service's home folder, for example:

```
cd inventory-helidon
```

2. Execute the build script:

```
./build.sh
```
