_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Grabdish Application Provisioning

These notes assume that you are running on a supported shell (Cloud shell, Linux or macOS) and have cloned the code.

The code that provisions the Grabdish application is located in the grabdish/config folder.  The grabdish application is designed to work on any Kubernetes cluster and database.  This provisioning is performed automatically when provisioning the dcms-oci workshop.

## Prerequisites

The following are required before provisioning Grabdish:
1. Kubernetes cluster with kubectl configured
2. One or two databases
3. An OCI object store bucket (ATP 2DB only)
4. get_secret bash function (available in infra/vault/folder)
5. sqlplus installed

## Input Parameters

To provision Grabdish the following parameters are passed:

- **DB_DEPLOYMENT:**      1DB (future) or 2DB
- **DB_TYPE:**            sa (stand alone, future) or atp
- **QUEUE_TYPE:**         classicq or teq (future)
- **DB_PASSWORD_SECRET:** Name of the secret holding the database password accessed by function get_secret (see below)
- **UI_PASSWORD_SECRET:** Name of the secret holding the UI password accessed by function get_secret (see below)
- **DB1_TNS_ADMIN:**      Folder containing DB1's TNS_ADMIN folder
- **DB1_ALIAS:**          TNS alias of DB1
- **DB2_TNS_ADMIN:**      Folder containing DB2's TNS_ADMIN folder (null for 1DB only)
- **DB2_ALIAS:**          TNS alias of DB2 (null for 1DB only)
- **CWALLET_OS_BUCKET:**  Bucket where the wallet token can be installed (null if not ATP)
- **OCI_REGION:**         The name of the OCI_REGION.  Used to construct a URL for wallet tokens (null if not ATP)
- **GRABDISH_LOG:**       Location to create log files

## Secret management

The bash get_secret function must be exported and return the DB and UI passwords when called, for example:

  DB_PASSWORD=$(get_secret DB_PASSWORD_SECRET).

See infra/vault/folder for an implementation.

## Outputs

The output of provisioning provides the following environment variables:

- ORDER_DB_NAME
- ORDER_DB_ALIAS
- ORDER_DB_TNS_ADMIN
- INVENTORY_DB_NAME:
- INVENTORY_DB_ALIAS:
- INVENTORY_DB_TNS_ADMIN:

## Provisioning Steps

1. Source the common environment:

  source microservices-datadriven/common/source.env

2. Create a folder to store the provisioning state and make this the current directory, for example:

```
STATE='$HOME/grabdish'
mkdir -p $STATE
cd $STATE
```

3. Create an input.env file containing the parameters in bash source file format, for axample:

```
cat >$STATE/input.env <<!
DB_DEPLOYMENT='2DB'
DB_TYPE='atp'
QUEUE_TYPE='classicq'
DB_PASSWORD_SECRET='DB_PASSWORD_SECRET'
UI_PASSWORD_SECRET='DB_PASSWORD_SECRET'
DB1_NAME='DB1'
DB1_TNS_ADMIN='...'
DB1_ALIAS='...'
DB2_NAME='...'
DB2_TNS_ADMIN='...'
DB2_ALIAS='...'
CWALLET_OS_BUCKET='...'
OCI_REGION='...'
GRABDISH_LOG='...'
!
```

4. Provision Grabdish by running the following commands:

```
cd $STATE #Required
provisioning-apply $MSDD_APPS_CODE/grabdish/config
```

5. Source the output file:

source $STATE/output.env

## Teardown Steps

To teardown a previously provisioned Grabdish application follow these steps:

1. Source the common environment:

  source microservices-datadriven/common/source.env

2. Locate the directory where Grabdish was provisioned, for example:

```
STATE='$HOME/grabdish'
```

3. Execute the following command to undo the provisioning:

```
cd $STATE #Required
provisioning-destroy
```
