ARG CP_VERSION=0.5.0
ARG KAFKA_CONNECT_DATAGEN_VERSION=6.2.1

ARG BASE_PREFIX=cnfldemos 
ARG CONNECT_IMAGE=cp-server-connect-datagen

FROM $BASE_PREFIX/$CONNECT_IMAGE:$CP_VERSION-$KAFKA_CONNECT_DATAGEN_VERSION

ENV CONNECT_HUB_COMPONENTS_PATH="/usr/share/confluent-hub-components"
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"

RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jms-sink:latest
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jms:latest

COPY lib/*.jar ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms-sink/lib/
COPY lib/*.jar ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms/lib/
COPY wallet/* /home/appuser/wallet/


ENV TNS_ADMIN="/home/appuser/wallet"

USER root
RUN  chown appuser:appuser ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms-sink/lib/*
RUN  chown appuser:appuser ${CONNECT_HUB_COMPONENTS_PATH}/confluentinc-kafka-connect-jms/lib/*
RUN  chmod 777 /home/appuser/wallet/*
