#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e

DIRNAME=$(state_get RUN_NAME)
{
  echo "# LiveLab Setup -- BEGIN"
  echo "export LAB_HOME=${HOME}/${DIRNAME}/microservices-datadriven/workshops/txeventq-kafka"
  echo "export JAVA_HOME=${JAVA_HOME}"
  echo "export PATH=${JAVA_HOME}/bin/:${LAB_HOME}/cloud-setup/utils:${LAB_HOME}/cloud-setup/cmd:${PATH}"
  echo "source ${LAB_HOME}/cloud-setup/env.sh"
  echo "# LiveLab Setup -- END"
} >> "${HOME}"/.bashrc

state_set_done BASH_SETUP
