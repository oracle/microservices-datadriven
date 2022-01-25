#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Install Docker Compose
while ! state_done DOCKER_COMPOSE; do
  if ! test -f "$LAB_HOME"/cloud-setup/confluent-kafka/docker-compose; then
    curl -sL "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o "$LAB_HOME"/cloud-setup/confluent-kafka/docker-compose
    chmod +x "$LAB_HOME"/cloud-setup/confluent-kafka/docker-compose
  fi
  state_set_done DOCKER_COMPOSE
done

# Build Confluent Kafka Connect Customer Image
while ! state_done CFLCONNECT_IMAGE; do
  cd "$LAB_HOME"/cloud-setup/confluent-kafka

  # Get the Connect Dependencies
  mvn clean install -DskipTests

  # Get Oracle DB Wallet
  mkdir wallet
  cp "$LAB_HOME"/wallet/* ./wallet/

  # Build the Kafka Connect Custom Image
  docker build . -t cp-kafka-connect-custom:0.1.0

  # Clean up the project folder.
  rm -rf wallet
  state_set_done CFLCONNECT_IMAGE
done

# Setup Kafka
while ! state_done KAFKA_SETUP; do
  cd "$LAB_HOME"/cloud-setup/confluent-kafka
  ./docker-compose up --no-start
  cd "$LAB_HOME"
  state_set_done KAFKA_SETUP
done
