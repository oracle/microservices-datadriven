#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './setup.sh'"
  exit 1
fi

# Environment must be setup before running this script
if test -z "$DCMS_CICD_STATE_DIR"; then
  echo "ERROR: Workshop environment not setup"
  exit 1
fi

# Setup the state store
if ! state-store-setup "$DCMS_CICD_STORE_DIR" "$DCMS_CICD_LOG_DIR/state.log"; then
  echo "Error: Provisioning the state store failed"
  exit 1
fi

# Get the setup status
if ! DCMS_STATUS=$(provisioning-get-status $DCMS_CICD_STATE_DIR); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

case "$DCMS_STATUS" in

  applied | byo)
    # Nothing to do
    exit 0
    ;;

  applying)
    # Nothing to do
    exit 0
    ;;

  destroying | destroying-failed )
    # Cannot setup during destroy phase
    echo "ERROR: Destroy is running and so cannot run setup"
    exit 1
    ;;

  applying-failed)
    # Restart the setup
    cd $DCMS_CICD_STATE_DIR
    echo "Restarting setup.  Call 'jenkins-status' to get the status of the setup"
    nohup bash -c "provisioning-apply $MSDD_WORKSHOP_CODE/$DCMS_CICD_WORKSHOP/config" >>$DCMS_CICD_LOG_DIR/setup.log 2>&1 &
    exit 0
    ;;

  new)
    # New setup
    ;;

esac

##### New Setup
# Register our source.env in .bash_profile
PROF=~/.bashrc
if test -f "$PROF"; then
  sed -i.bak '/microservices-datadriven/d' $PROF
fi
echo "source $MSDD_WORKSHOP_CODE/$DCMS_CICD_WORKSHOP/source.env #microservices-datadriven" >>$PROF
echo 'echo "Running workshop from folder $MSDD_WORKSHOP_CODE #microservices-datadriven"' >>$PROF

# Run Name (random)
if ! state_done RUN_NAME; then
  state_set RUN_NAME gd`awk 'BEGIN { srand(); print int(1 + rand() * 100000000)}'`
fi

# Request compartment details and create or validate
if ! state_done COMPARTMENT_OCID; then
  if compartment-dialog "$(state_get RUN_TYPE)" "$(state_get TENANCY_OCID)" "$(state_get HOME_REGION)" "GrabDish Workshop $(state_get RUN_NAME)"; then
    state_set COMPARTMENT_OCID $COMPARTMENT_OCID
  else
    echo "Error: Failed in compartment-dialog"
    exit 1
  fi
fi

# Setup the vault
if ! folder-vault-setup $DCMS_CICD_VAULT_DIR; then
  echo "Error: Failed to provision the folder vault"
  exit 1
fi

# OCI Region
while ! state_done OCI_REGION; do
  if test -z "$OCI_REGION"; then
    if test 1 -eq `oci iam region-subscription list --query 'length(data[])' --raw-output`; then
      # Only one subcribed region so must be home region
      OCI_REGION="$(state_get HOME_REGION)"
    else
      read -p "Please enter the name of the region that you are connected to: " OCI_REGION
    fi
  fi
  state_set OCI_REGION "$OCI_REGION"
done

# Get OCID of Grabdish DB
while ! state_done AUTONOMOUS_DATABASE_ID; do
  if [[ -f $DCMS_CICD_RUN_DIR/../dcms-oci-run/state/infra/db/db2/terraform/terraform.tfstate ]]; then
    echo "Getting OCID of Grabdish DB"
    cd $DCMS_CICD_RUN_DIR/../dcms-oci-run/state/infra/db/db2/terraform/ && ADB_OCID=$(terraform output db_ocid|jq -r .)
  fi
  if [[ -z ${ADB_OCID} ]]; then
    echo "Unable to find OCID of Autonomous Database; please wait until GrabDish has been provisioned and retry"
    exit 1
  fi
  state_set AUTONOMOUS_DATABASE_ID "${ADB_OCID}"
done

# Select Jenkins Deployment
echo 'Jenkins Deployment Options'
PS3='Please select Jenkins deployment type: '
options=("Micro-Deployed Jenkins on Public VM" "Micro-deployed Jenkins on Private VM" "Distributed Builds with Jenkins on Private VM" "Oracle DevOps" "Cancel")
select opt in "${options[@]}"
do
    case $opt in
        "Micro-Deployed Jenkins on Public VM")
                CONFIGURATION='MDPUBJ'
                echo "You have selected Micro-Deployed Jenkins on Public VM"
                break
                ;;
        "Micro-deployed Jenkins on Private VM")
                    CONFIGURATION='MDPRVJ'
                    echo "You have selected Micro-Deployed Jenkins on Private VM"
                    break
                    ;;
        "Distributed Builds with Jenkins on Private VM")
            CONFIGURATION='DBPRVJ'
            echo "You have selected Distributed Builds with Jenkins on Private VM"
            break
            ;;
        "Oracle DevOps")
            CONFIGURATION='DEVOPS'
            echo "You have selected Oracle DevOps service"
            break
            ;;
        "Cancel")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
state_set JENKINS_DEPLOYMENT $CONFIGURATION
echo ""


# Collect Agent Names
if [ "$(state_get JENKINS_DEPLOYMENT)" = "DBPRVJ" ]
then
  read -p "Please enter a list of Jenkins Agent names to provision separated by spaces:" AGENTS
  # Expects a string with names split with spaces
  state_set JENKINS_AGENTS "$AGENTS"
fi
echo ""

# Collect Jenkins password
if ! is_secret_set JENKINS_PASSWORD; then

    if test -z "${TEST_JENKINS_PASSWORD-}"; then
      read -s -r -p "Enter the password to be used for Jenkins: " PW
    else
      PW="${TEST_JENKINS_PASSWORD-}"
    fi

  set_secret JENKINS_PASSWORD $PW
  state_set JENKINS_PASSWORD_SECRET "JENKINS_PASSWORD"
  echo ""
fi

# Run the setup in the background
cd $DCMS_CICD_STATE_DIR
echo "Setup running in background.  Call 'jenkins-status' to get the status of the setup"
nohup bash -c "provisioning-apply $MSDD_WORKSHOP_CODE/$DCMS_CICD_WORKSHOP/config" >>$DCMS_CICD_LOG_DIR/setup.log 2>&1 &
