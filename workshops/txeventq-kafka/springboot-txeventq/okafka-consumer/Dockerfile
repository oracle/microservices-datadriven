## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
FROM ghcr.io/graalvm/graalvm-ce:ol8-java11

ARG IMAGE_NAME=oracle-developers-okafka-consumer
ARG IMAGE_VERSION=0.0.1-SNAPSHOT

ENV ENV_IMAGE_NAME=${IMAGE_NAME}
ENV ENV_IMAGE_VERSION=${IMAGE_VERSION}

COPY target/${ENV_IMAGE_NAME}-${ENV_IMAGE_VERSION}.jar ${ENV_IMAGE_NAME}-${ENV_IMAGE_VERSION}.jar
COPY wallet/* /home/appuser/wallet/

ENV TNS_ADMIN="/home/appuser/wallet"

USER root
RUN  chmod 777 /home/appuser/wallet/*

EXPOSE 8081

ENTRYPOINT java -jar ${ENV_IMAGE_NAME}-${ENV_IMAGE_VERSION}.jar