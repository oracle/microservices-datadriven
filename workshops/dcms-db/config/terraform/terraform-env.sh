# Populate <> values and source before running terraform as per the README.md
# Required for the OCI Provider
export TF_VAR_region="$(state_get OCI_REGION)"
export TF_VAR_tenancy_ocid="$(state_get TENANCY_OCID)"
export TF_VAR_compartment_ocid="$(state_get COMPARTMENT_OCID)"
export TF_VAR_user_ocid="$(state_get USER_OCID)"
export TF_VAR_db_name="$(state_get DB_NAME)"
export TF_VAR_ssh_public_key_file="$(state_get SSH_PUBLIC_KEY_FILE)"
export TF_VAR_ssh_private_key_file="$(state_get SSH_PRIVATE_KEY_FILE)"

# Set the Project Abbreviation (default apexpoc)
export TF_VAR_proj_abrv="dcms-db"

# Set the Environment, refer to README.md for differences (default ALf)
# export TF_VAR_size="<ALF|S|M|L|XL>"
export TF_VAR_size="ALF"

# Setup logging just in case something fails
export TF_LOG=TRACE
export TF_LOG_PATH="terraform.log"
