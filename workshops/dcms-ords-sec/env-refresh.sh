#!/usr/bin/env bash
# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

export SSH_ords=$(terraform output -json bastion_ssh_cmd | jq -r '.')
export LB=$(terraform output -json lb_address | jq -r '.')
export ADM_GROUP=Administrators
export TF_VAR_proj_abrv=$(echo ${TF_VAR_proj_abrv}| tr '[:lower:]' '[:upper:]')
export TF_VAR_size=$(echo ${TF_VAR_size}| tr '[:lower:]' '[:upper:]')
export COMP_NAME=$(oci iam compartment get --compartment-id $TF_VAR_compartment_ocid --query data.name --raw-output)
export load_balancer_id=$(oci lb load-balancer list --compartment-id $TF_VAR_compartment_ocid --query 'data[0]."id"' --raw-output )
export vcn_ocid=$(oci network vcn list --compartment-id $TF_VAR_compartment_ocid --display-name $TF_VAR_proj_abrv-vcn --query 'data[0]."id"'  --raw-output)
export TF_VAR_subnet_public=$(oci network subnet list --compartment-id $TF_VAR_compartment_ocid --display-name $TF_VAR_proj_abrv-subnet-public --query 'data[0]."id"' --raw-output)
export TF_VAR_nsg_apigw=$(oci network nsg list --compartment-id $TF_VAR_compartment_ocid --display-name $TF_VAR_proj_abrv-security-group-apigw --query 'data[0]."id"' --raw-output)
export api_gw_id=$(oci api-gateway gateway list --compartment-id $TF_VAR_compartment_ocid --query 'data.items[0]."id"' --raw-output --all)
export api_gw_base_url=$(oci api-gateway gateway list --compartment-id $TF_VAR_compartment_ocid --query 'data.items[0]."hostname"' --raw-output --all)
export LB=$(terraform output -json lb_address | jq -r '.')
export api_gw_deploy=$(oci api-gateway deployment list  --compartment-id $TF_VAR_compartment_ocid --query 'data.items[0]."id"' --raw-output --all)
export api_gw_deploy_path=$(oci api-gateway deployment get --deployment-id $api_gw_deploy --query 'data.specification.routes[0]."path"' --raw-output)
export gw_url=$(oci api-gateway deployment get --deployment-id $api_gw_deploy --query data.endpoint --raw-output)
export gw_url_emp=$gw_url'/ordstest/examples/employees/'
export api_gw_id=$(oci api-gateway gateway list --compartment-id $TF_VAR_compartment_ocid --query 'data.items[0]."id"' --raw-output --all)
export api_gw_ip=$(oci api-gateway gateway get --gateway-id ${api_gw_id} --query 'data."ip-addresses"[0]."ip-address"' --raw-output)
export nsg_id=$(oci network nsg list --compartment-id $TF_VAR_compartment_ocid --display-name $TF_VAR_proj_abrv-security-group-apigw --query 'data[0]."id"' --raw-output)
echo SSH_ords
echo $SSH_ords
echo LB
echo $LB
echo ADM_GROUP
echo $ADM_GROUP
echo TF_VAR_proj_abrv
echo $TF_VAR_proj_abrv
echo TF_VAR_size
echo $TF_VAR_size
echo COMP_NAME
echo $COMP_NAME
echo load_balancer_id
echo $load_balancer_id
echo vcn_ocid
echo $vcn_ocid
echo TF_VAR_nsg_apigw
echo $TF_VAR_nsg_apigw
echo TF_VAR_subnet_public
echo $TF_VAR_subnet_public
echo TF_VAR_nsg_apigw
echo $TF_VAR_nsg_apigw
echo 
echo api_gw_id
echo $api_gw_id
echo api_gw_base_url
echo $api_gw_base_url
echo api_gw_deploy
echo $api_gw_deploy
echo api_gw_deploy_path
echo $api_gw_deploy_path
echo gw_url
echo $gw_url
echo gw_url_emp
echo $gw_url_emp
echo api_gw_id
echo $api_gw_id
echo api_gw_ip
echo $api_gw_ip





