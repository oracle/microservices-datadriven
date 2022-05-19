#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

DIRNAME=$(state_get RUN_NAME)
{
  echo "# LiveLab Setup -- BEGIN"
  echo "export LAB_HOME=${HOME}/${DIRNAME}/microservices-datadriven/workshops/oracleteq-kafka"
  echo "export JAVA_HOME=${HOME}/graalvm-ce-java11-${GRAALVM_VERSION}"
  echo "LAB_PATH=${LAB_HOME}/cloud-setup/utils"
  echo "LAB_PATH=${LAB_HOME}/cloud-setup/cmd:${LAB_PATH}"
  echo "export PATH=${JAVA_HOME}/bin/:${LAB_PATH}:${PATH}"
  echo "# LiveLab Setup -- END"
} >> "${HOME}"/.bashrc

source "${HOME}"/.bashrc

state_set_done BASH_SETUP
