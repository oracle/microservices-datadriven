#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

# Install Docker Compose
while ! state_done DOCKER_COMPOSE; do
  if ! test -f "$LAB_HOME"/cloud-setup/confluent/docker-compose; then
    curl -sL "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o "$LAB_HOME"/cloud-setup/confluent/docker-compose
    chmod +x "$LAB_HOME"/cloud-setup/confluent/docker-compose
  fi
  state_set_done DOCKER_COMPOSE
done



# Setup Kafka
while ! state_done KAFKA_SETUP; do
  cd "$LAB_HOME"/cloud-setup/confluent
  ./docker-compose up --no-start
  cd "$LAB_HOME"
  state_set_done KAFKA_SETUP
done
