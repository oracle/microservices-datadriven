# Installing Cloudbank v5

This repo contains a almost ready deployment of cloudbank v5. There are minimal changes to make this work in your environment. **NOTE:** this example assumes that OBaaS is installed in a namespace called `obaas-dev` and that CBv5 will be installed in the same namespace called `obaas-dev`.

Cluudbank v5 has only been tested on Java 21.

You must set the DOCKER_HOST variable to be able to build CLoudbank v5, for example if you're using Rancher Desktop on a Mac `export DOCKER_HOST=unix:///Users/atael/.rd/docker.sock`.

**NOTE** the repositories must by public. Needs to investigate why private repos aren't working (authentication error). You can use the script `create-oci-repos.sh` to create the necessary repositories. For example `source create-oci-repos.sh andytael sjc.ocir.io/maacloud/cloudbank`.

## Dependencies for Cloudbank

Build dependencies and install  -- `mvn clean install -pl common,buildtools`

## Build cloudbank

A script called `update-jkube-image.sh` is provided to update the `pom.xml` file for JKube to point to the repository that will be used (update-jkube-image.sh <new-image-prefix> (sjc.ocir.io/maacloud/cloudbank-v5 for example)). Execute the following command to build and push the images:

```bash
mvn clean package k8s:build k8s:push -pl account,customer,transfer,checks,creditscore,testrunner
```

## Create account and customer DB users

Update the `sqljob.yaml` file to reflect your environment. Run the job and **VERIFY** that the job finished successfully before proceeding.

```bash
k create -f sqljob.yaml
```

## Create secrets for account and customer microservices

A script called `acc_cust_secrets.sh` is provided that could be used create the necessary secrets. This script *MUST* be updated to reflect your environment.

## Change values.yaml

A script called `update_image.sh` is provided that could be used to change the repository and tag to your environment (`./update-image.sh <repository> <tag>`) in the `values.yaml` file. For example `update-image.sh sjc.ocir.io/maacloud/cloudbank-v5 0.0.1-SNAPSHOT`.

Verify and change credentialSecret and walletSecret values in the `values.yaml` if needed. Names can be found be looking at the secrets in the `obaas-dev` namespace.

## Install CBv5

A script call `deploy-all-services.sh` is provided that can be used to deploy all the Cloudbank services (account,customer,transfer,checks,creditscore,testrunner). For ecample `./deploy-all-services.sh obaas-dev`.

## Create APISIX routes

1. Retrieve the API KEY (requires `yq`) for APISIX by running this command:

```bash
kubectl -n obaas-dev get configmap apisix -o yaml | yq '.data."config.yaml"' | yq '.deployment.admin.admin_key[] | select(.name == "admin") | .key'
```

1. Create the routes by running this command:

```bash
(cd apisix-routes; source ./create-all-routes.sh <YOUR-API-KEY>)
```

## Test the services

Follow the [README](README.md) section `Test CloudBank Services`.
