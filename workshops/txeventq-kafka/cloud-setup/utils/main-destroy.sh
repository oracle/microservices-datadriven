#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Switch to SSH Key auth for the oci cli (workaround to perm issue awaiting fix)
# source $LAB_HOME/cloud-setup/utils/oci-cli-cs-key-auth.sh


# Remove from .bashrc
sed -i.bak '/txeventqlab/d' ~/.bashrc


# No destroy necessary for Live Labs
if test "$(state_get RUN_TYPE)" == "3"; then
  echo "No teardown required for Live Labs"
  exit
fi

# Run the graalvm-uninstall.sh in the background
if ps -ef | grep "${LAB_HOME}/cloud-setup/java/graalvm-uninstall.sh" | grep -v grep; then
  echo "${LAB_HOME}/cloud-setup/java/graalvm-uninstall.sh is already running"
else
  echo "Executing java/graalvm-uninstall.sh in the background"
  nohup "${LAB_HOME}"/cloud-setup/java/graalvm-uninstall.sh &>> "${LAB_LOG}"/graalvm-uninstall.log &
fi

# Run the objstore-destroy.sh in the background
if ps -ef | grep "${LAB_HOME}/cloud-setup/utils/objstore-destroy.sh" | grep -v grep; then
  echo "${LAB_HOME}/cloud-setup/utils/objstore-destroy.sh is already running"
else
  echo "Executing objstore-destroy.sh in the background"
  nohup "${LAB_HOME}"/cloud-setup/utils/objstore-destroy.sh &>> "${LAB_LOG}"/objstore-destroy.log &
fi

# Run the objstore-destroy.sh in the background
if ps -ef | grep "${LAB_HOME}/cloud-setup/utils/terraform-destroy.sh" | grep -v grep; then
  echo "${LAB_HOME}/cloud-setup/utils/terraform-destroy.sh is already running"
else
  echo "Executing terraform-destroy.sh in the background"
  nohup "${LAB_HOME}"/cloud-setup/utils/terraform-destroy.sh &>> "${LAB_LOG}"/terraform-destroy.log &
fi

