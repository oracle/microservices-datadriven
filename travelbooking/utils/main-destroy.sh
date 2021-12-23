#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -e


# Switch to SSH Key auth for the oci cli (workaround to perm issue awaiting fix)
# source $TRAVELBOOKING_HOME/utils/oci-cli-cs-key-auth.sh


# Remove from .bashrc
sed -i.bak '/travelbookingsaga/d' ~/.bashrc


# No destroy necessary for Live Labs
if test "$(state_get RUN_TYPE)" == "3"; then
  echo "No teardown required for Live Labs"
  exit
fi


# Run the os-destroy.sh in the background
if ps -ef | grep "$TRAVELBOOKING_HOME/utils/os-destroy.sh" | grep -v grep; then
  echo "$TRAVELBOOKING_HOME/utils/os-destroy.sh is already running"
else
  echo "Executing os-destroy.sh in the background"
  nohup $TRAVELBOOKING_HOME/utils/os-destroy.sh &>> $TRAVELBOOKING_LOG/os-destroy.log &
fi


# Run the repo-destroy.sh in the background
if ps -ef | grep "$TRAVELBOOKING_HOME/utils/repo-destroy.sh" | grep -v grep; then
  echo "$TRAVELBOOKING_HOME/utils/repo-destroy.sh is already running"
else
  echo "Executing repo-destroy.sh in the background"
  nohup $TRAVELBOOKING_HOME/utils/repo-destroy.sh &>> $TRAVELBOOKING_LOG/repo-destroy.log &
fi


# Run the lb-destroy.sh in the background
if ps -ef | grep "$TRAVELBOOKING_HOME/utils/lb-destroy.sh" | grep -v grep; then
  echo "$TRAVELBOOKING_HOME/utils/lb-destroy.sh is already running"
else
  echo "Executing lb-destroy.sh in the background"
  nohup $TRAVELBOOKING_HOME/utils/lb-destroy.sh &>> $TRAVELBOOKING_LOG/lb-destroy.log &
fi


# Terraform Destroy
echo "Running terraform destroy"
cd $TRAVELBOOKING_HOME/terraform
export TF_VAR_ociTenancyOcid="$(state_get TENANCY_OCID)"
export TF_VAR_ociUserOcid="$(state_get USER_OCID)"
export TF_VAR_ociCompartmentOcid="$(state_get COMPARTMENT_OCID)"
export TF_VAR_ociRegionIdentifier="$(state_get REGION)"
export TF_VAR_runName="$(state_get RUN_NAME)"
export TF_VAR_travelagencyDbName="$(state_get TRAVELAGENCYDB_NAME)"
export TF_VAR_participantDbName="$(state_get PARTICIPANTDB_NAME)"
terraform init
terraform destroy -auto-approve


# If BYO K8s then delete the msdataworkshop namespace in k8s
if state_done BYO_K8S; then
  kubectl delete ns msdataworkshop
fi
