ARG CP_VERSION=0.5.0
ARG KAFKA_CONNECT_VERSION=7.0.1

ARG BASE_PREFIX=confluentinc 
ARG CONNECT_IMAGE=cp-kafka-connect

FROM $BASE_PREFIX/$CONNECT_IMAGE:$KAFKA_CONNECT_VERSION

ENV CONNECT_HUB_COMPONENTS_PATH="/usr/share/confluent-hub-components"
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jms-sink:latest
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jms:latest

COPY target/dependency/*.jar ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms-sink/lib/
COPY target/dependency/*.jar ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms/lib/

RUN  mkdir /home/appuser/wallet 
COPY wallet/* /home/appuser/wallet/

ENV TNS_ADMIN="/home/appuser/wallet"

## Run this code to ADB-D
#RUN mkdir /home/appuser/.oci
#COPY oci/* /home/appuser/.oci/

USER root
RUN  chown appuser:appuser ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms-sink/lib/*
RUN  chown appuser:appuser ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms/lib/*
RUN  chmod 777 /home/appuser/wallet/*

## Run this code to ADB-D
#RUN  yum update -y && yum upgrade -y
#RUN  yum install openssh-clients -y
