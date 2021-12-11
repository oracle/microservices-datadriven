_Copyright (c) 2019, 2020, 2021 Oracle and/or its affiliates The Universal Permissive License (UPL), Version 1.0_  

# Grabdish Application Provisioning, Build and Deployment

These notes assume that you are running on a supported shell (Cloud shell, Linux or macOS) and have cloned the code.

## Provisioning

The code that provisions the Grabdish application is located in the grabdish/config folder.  The grabdish application is designed to work on any Kubernetes cluster and database.  This provisioning is performed automatically when provisioning the dcms-oci workshop.

### Prerequisites

The following are required before provisoning grabdish:
1. Kubernetes cluster with kuebctl configured
2. One or two databases
3. An OCI object store bucket (ATP only)
4. get_secret bash function (available in infra/vault/folder)
5. sqlplus installed

### Input Parameters

To provision grabdish the following parameters are required:

DB_DEPLOYMENT:      1db (future) or 2db
DB_TYPE:            sa (stand alone, future) or atp
QUEUE_TYPE:         classicq or teq (future)
DB_PASSWORD_SECRET: Name of the secret holding the database password accessed by function get_secret (see below)
UI_PASSWORD_SECRET: Name of the secret holding the UI password accessed by function get_secret (see below)
DB1_TNS_ADMIN:      Folder containing DB1's TNS_ADMIN folder
DB1_ALIAS:          TNS alias of DB1
DB2_TNS_ADMIN:      Folder containing DB2's TNS_ADMIN folder (null for 1db only)
DB2_ALIAS:          TNS alias of DB2 (null for 1db only)
CWALLET_OS_BUCKET:  Bucket where the wallet token can be installed (null if not ATP)
OCI_REGION:         The name of the OCI_REGION.  Used to construct a URL for wallet tokens (null if not ATP)
GRABDISH_LOG:       Location to create log files

### Secret management

The bash get_secret function must be exported and return the DB and UI passwords when called, for example:

  DB_PASSWORD=$(get_secret DB_PASSWORD_SECRET).

### Outputs

The output of provisioning provides the following environment variables:

ORDER_DB_NAME 
ORDER_DB_ALIAS 
ORDER_DB_TNS_ADMIN 
INVENTORY_DB_NAME:
INVENTORY_DB_ALIAS:
INVENTORY_DB_TNS_ADMIN:

### Provisioning Steps

1. Source the common environment:

  source microservices-datadriven/common/source.env

2. Create a folder to store the provisioning state and make this the current directory, for example:

  STATE='grabdish'
  mkdir -p $STATE
  cd $STATE

3. Create an input.env file containing the parameters in bash source file format, for axample:

cat >$STATE/input.env <<!
DB_DEPLOYMENT='2db'
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

4. Provision grabdish by running the following command:

provisioning-apply $MSDD_APPS_CODE/grabdish/config

5. Source the output file:

source $STATE/output.env

## Build

It is necessary to build the grabdish microservices before they can be deployed.  Each microservice has its own build script.  A build script compiles the code, constructs a docker image, and pushes the image to the repository.  The image is used when deploying he microservice.  It is possible to run the builds and provisioning in parallel to save time.  

Building more than one java based microservice build in parallel within the same user has been found to be unreliable and so is not recommended.

### Prerequisites

The following are required before provisoning grabdish:
1. Kubernetes cluster with kubectl configured
2. One or two databases
3. An OCI object store bucket (ATP only)
4. get_secret bash function (available in infra/vault/folder)
5. Java installed
6. Docker installed
7. Docker repository prepared 
8. Software cloned

### Environment Variables

To build grabdish services the following environment variables must be exported:

DOCKER_REGISTRY
JAVA_HOME
PATH=${JAVA_HOME}/bin:$PATH

### Steps

1. Change to a service's home folder, for example:

cd inventory-helidon

2. Execute the build script:

./build.sh

## Deploy

### Environment Variables

To deploy grabdish services the following environment variables must be exported.  Note, most of these are outputs from the provisioning process: 

ORDER_DB_NAME
ORDER_DB_TNS_ADMIN
ORDER_DB_ALIAS
INVENTORY_DB_NAME
INVENTORY_DB_TNS_ADMIN
INVENTORY_DB_ALIAS
OCI_REGION:                   OCI vault only
VAULT_SECRET_OCID:            OCI vault only

### Steps

1. Change to a service's home folder, for example:

cd inventory-helidon

2. Execute the build script:

./deploy.sh
