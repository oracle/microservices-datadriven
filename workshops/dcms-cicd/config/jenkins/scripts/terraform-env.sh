# Terraform variables
export TF_VAR_region="$(state_get OCI_REGION)"
export TF_VAR_compartment_ocid="$(state_get COMPARTMENT_OCID)"
export TF_VAR_jenkins_password="${state_get JENKINS_PASSWORD_SECRET}"

# Setup logging just in case something fails
export TF_LOG=TRACE
export TF_LOG_PATH="terraform.log"