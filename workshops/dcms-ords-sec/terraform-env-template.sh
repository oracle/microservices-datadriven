#!/usr/bin/env bash
# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

if ! (return 0 2>/dev/null); then
	echo "ERROR: This script must be sourced" && exit 1
fi

# Unset Previously set Vars
# compgen doesn't work Catalina or Monterey
# unset $(compgen -v | grep "TF_VAR")

# Unset Previously set Vars
for x in $(env|grep TF_VAR_); do
	unset ${x//=*}
done

# If using Cloud Shell modify the following variables 
if [[ ! -z ${OCI_CS_TERMINAL_OCID} ]]; then
	# If using Cloud Shell modify the following variables
	export TF_VAR_region=${OCI_REGION}
	export TF_VAR_tenancy_ocid=${OCI_TENANCY}
	export TF_VAR_compartment_ocid="[COMPARTMENT_OCID]"
	export TF_VAR_proj_abrv="[ABBRV]"
else
	# If using Local Machine Deployment modify the following variables
	# Prevent Cloud-Shell Auth
	unset OCI_AUTH
	export TF_VAR_region="[REGION]"
	export TF_VAR_tenancy_ocid="[TENANCY_OCID]"
	export TF_VAR_compartment_ocid="[COMPARTMENT_CID]"
	export TF_VAR_user_ocid="[USER_OCID]"
	export TF_VAR_proj_abrv="[ABBRV]"
	export TF_VAR_fingerprint="[FINGERPRINT]"
	export TF_VAR_private_key_path="[PATH_TO_OCI_PRIVATE_KEY]"
fi

# Do NOT change this value
export TF_VAR_size="XS"

# uppercase 
export TF_VAR_proj_abrv=$(echo ${TF_VAR_proj_abrv}| tr '[:lower:]' '[:upper:]')
export TF_VAR_size=$(echo ${TF_VAR_size}| tr '[:lower:]' '[:upper:]')

# Terraform commands
alias tf=terraform
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tff='terraform fmt'
alias tfi='terraform init'
alias tfo='terraform output'
alias tfp='terraform plan'
alias tfv='terraform validate'
