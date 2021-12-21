_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Grabdish Deployment

## Environment Variables

To deploy grabdish services the following environment variables must be exported.  Note, most of these are outputs from the provisioning process:

- ORDER_DB_NAME
- ORDER_DB_TNS_ADMIN
- ORDER_DB_ALIAS
- INVENTORY_DB_NAME
- INVENTORY_DB_TNS_ADMIN
- INVENTORY_DB_ALIAS
- OCI_REGION:                   OCI vault only
- VAULT_SECRET_OCID:            OCI vault only

## Deploy Steps

1. Source the common environment:

  source microservices-datadriven/common/source.env

2. Change to a microservice's home folder, for example:

```
cd inventory-helidon
```

3. Execute the deploy script:

```
./deploy.sh
```

## Undeploy Steps

1. Source the common environment:

  source microservices-datadriven/common/source.env

2. Change to a microservice's home folder, for example:

```
cd inventory-helidon
```

3. Execute the undeploy script:

```
./undeploy.sh
```

## Internals

The deploy.sh and undeploy.sh scripts use the k8s_deploy andf k8s_undeploy helper functions respectively, defined in common/utils/deploy-functions.env and sourced by common/source.env.  See common/docs/DeployFunctions.md for details.
