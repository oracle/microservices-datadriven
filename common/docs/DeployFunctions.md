_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Deployment Functions

The deployment helper functions are defined in common/utils/deploy-functions.env and sourced by common/source.env.  They are used to streamline the deployment of microservices.

## k8s_deploy

Deploy a set of yaml files.  The function accepts a single parameter that represents a space separate list of yaml files to be deployed, for example:

```
k8s-deploy 'inventory-helidon-deployment.yaml inventory-service.yaml'
```

### Internals

kubectl apply is used to deploy the files and so the k8s_deploy function is idempotent.

The yaml files are expected to be in the same folder as the script that invokes this function.

The yaml files are processed to substitute environment variables before they are deployed.  The processed yaml files are place in the .deployed folder in the home directory of the microservice.  

The syntax available to define substitution variable is as follows:

- **${VAR}**          Fails if VAR is undefined, else is substitutes the value of VAR
- **${VAR-default}**  If VAR is not defined substitute 'default', else substitutes the value of VAR
- **${VAR-}**         If VAR is not defined substitute '', else it substitutes the value of VAR
- **${VAR?MSG}**      Fails if VAR is undefined with the error 'MSG', else it substitutes value of VAR
- **${VAR:-default}** If VAR is not defined or empty, substitute 'default', else it substitutes the value of VAR
- **${VAR:?MSG}**     Fails if VAR is undefined or empty with the error 'MSG', else it substitutes the value of VAR

Here is an example:

```
- name: OCI_REGION
  value: "${OCI_REGION-}"
```

## k8s_undeploy

Undeploy the yaml files what were deployed by k82_deploy.  The files are undeployed in the reverse order.

### Internals

The yaml files of the deployed resources are found in the .deployed folder.  The files are deleted once thay have been undeployed.  

kubectl delete is used to undeploy the resources.
