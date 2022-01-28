_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Example 21c Provisioning

This workshop provisions two 21c databases.

The setup assumes that you are running on a supported shell (Cloud shell, Linux or macOS) and have cloned the code.

## Setup

Execute the following commands to start the setup:

```
source microservices-datadriven/workshops/example-21c/source.env
setup
```

The setup will ask for compartment details and a password for the databases.

The following environment variables with be set at the end of setup:

- DB1_ALIAS
- DB1_OCID
- DB1_TNS_ADMIN
- DB2_ALIAS
- DB2_OCID
- DB2_TNS_ADMIN

The parameter setting are also available in **$EG21C_STATE/output.env** file.

## Teardown

Execute the following commands to start the teardown:

```
teardown
```
