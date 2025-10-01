# Installing Cloudbank v5

This repo contains a almost ready deployment of cloudbank v5. There are minimal changes to make this work in your environment. **NOTE:** this example assumes that OBaaS is installed in a namespace called `obaas-dev` and that CBv5 will be installed in the same namespace called `obaas-dev`.

## Create account and customer DB users

Update the sqljob.yaml file to reflect your environment. Run the job and **VERIFY** that the job finished successfully before proceeding.

## Create secrets for account and customer microservices

A script called `acc_cust_secrets.sh` is provided that could be used to change the repository and tag to your environment. This script *MUST* be updated to reflect your environment.

## Change values.yaml

A script called `update_image.sh` is provided that could be used to change the repository and tag to your environment (`./update-image.sh <repository> <tag>`).

Verify and change credentialSecreat and walletSecret values in the `values.yaml` if needed. Names can be found be looking at the secrets in the `obaas-dev` namespace.

## Install CBv5

A script call `deploy-all-services.sh` is provided that can be used to deploy all the Cloudbank services.