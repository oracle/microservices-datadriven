#!/bin/bash
# Terraform variables
export TF_VAR_region="$(state_get OCI_REGION)"
export TF_VAR_compartment_ocid="$(state_get COMPARTMENT_OCID)"
export TF_VAR_deployment="$(state_get JENKINS_DEPLOYMENT)"
export TF_VAR_autonomous_database_id="$(state_get AUTONOMOUS_DATABASE_ID)"
export TF_VAR_jenkins_password="$(get_secret JENKINS_PASSWORD)"

if [ "$(state_get JENKINS_DEPLOYMENT)" = "DBPRVJ" ]
then
  # Expects a string with names split with spaces
  export TF_VAR_agents="$(state_get JENKINS_AGENTS)"
fi

# Setup logging just in case something fails
export TF_LOG=TRACE
export TF_LOG_PATH="terraform.log"
