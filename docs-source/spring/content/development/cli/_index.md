---
title: "OBaaS CLI"
description: "Command Line Interface for Oracle Backend for Microservices and AI"
keywords: "cli tool deployment spring springboot microservices development oracle backend"
---

The Oracle Backend for Microservices and AI offers a command-line interface (CLI), `oractl`. The CLI commands simplify the deployment of
microservices applications as well as bindings with the resources that they use. Download the CLI [here](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.3.1). The platform-specific binary can be renamed to `oractl` for convenience.

Table of Contents:

* [Installing the CLI](#installing-the-cli)
* [Using the CLI](#using-the-cli)
* [Command Concepts](#command-concepts)
* [Workflow Example](#workflow-example)
* [Available Command Groups](#available-commands)
  * [Help](#help)
  * [Connect to the backend](#connect)
  * [Manage Artifact](#artifact)
  * [Manage Binding](#binding)
  * [Manage Configuration](#bind)
  * [Manage Datastore](#deploy)
  * [Manage Identity](#create-autoscaler)
  * [Manage Image](#delete-autoscaler)
  * [Manage Namespace](#list)
  * [Manage Telemetry](#config)
  * [Manage Workload](#compile)
  * [ServerInfo](#user-management) 
* [Get Passwords](#get-passwords) 
* [Logging Information](#logging)

## Installing the CLI

Oracle Backend for Microservices and AI CLI is used to configure your backend and to deploy your Spring Boot applications to the backend.

1. Download the Oracle Backend for Microservices and AI CLI `oractl`

   Download the CLI from [here](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.3.1)

1. Rename the downloaded file to `oractl`

1. Add `oractl` to PATH variable

   You need to make sure it is executable and add it to your PATH environment variable.

    ```shell
    <copy>
    chmod +x oractl
    export PATH=/path/to/oractl:$PATH</copy>
    ```

**NOTE:** If environment is a Mac you need run the following command `sudo xattr -r -d com.apple.quarantine <downloaded-file>` otherwise will you get a security warning and the CLI will not work.

## Using the CLI

1. Expose the Oracle Backend for Microservices and AI Admin server that the CLI calls using this command:

    ```bash
    kubectl port-forward services/obaas-admin -n obaas-admin 8080
    ```

2. Start the CLI in interactive mode by running oractl from your terminal window. For example:

    ```bash
    oractl
    ```

    As a result, the `oractl` prompt is displayed as follows:

    ```text
       _   _           __    _    ___
       / \ |_)  _.  _. (_    /  |   |
       \_/ |_) (_| (_| __)   \_ |_ _|_
       ========================================================================================
       Application Name: Oracle Backend Platform :: Command Line Interface
       Application Version: (1.3.1)
       :: Spring Boot (v3.3.3) ::

       Ask for help:
       - Slack: https://oracledevs.slack.com/archives/C06L9CDGR6Z
       - email: obaas_ww@oracle.com

       oractl:>
    ```
       
## Command Concepts 

The following describes the different resources handled by the client:

* Artifacts - An artifact is a microservice JAR file uploaded to the backend. It is written to persistent storage1.

* Binding - A schema/user that is bound to a service deployment.

* Configuration - Application configurations managed by the Spring Cloud Config server.

* Datastore - Creates a database user and generates a secret in the app namespace containing that user and password8.

* Identity - Handles user management.

* Image - Manages image creation from artifacts.

* Namespace - An application namespace (Kubernetes namespace). The application namespace provides a mechanism for isolating groups of resources, especially the microservices.

* Telemetry - TBD

* Workload - Creates a Kubernetes deployment and service

## Workflow Example

Following is a worflow example deploying the Spring services that makeup the CloudBank backend.

Create the namespace for the CloudBank application
```
namespace create --namespace application
```
Create the datastore for the Account and Customer microservices
```
datastore create --namespace application --username account --id account
datastore create --namespace application --username customer --id customer
```
Upload the Spring microservice jars
```
artifact create --namespace application --workload account --imageVersion 0.0.1 --file /Users/devusr/microservices-datadriven/cloudbank-v4/account/target/account-0.0.1-SNAPSHOT.jar

artifact create --namespace application --workload checks --imageVersion 0.0.1 --file /Users/devusr/microservices-datadriven/cloudbank-v4/checks/target/checks-0.0.1-SNAPSHOT.jar

artifact create --namespace application --workload customer --imageVersion 0.0.1 --file /Users/devusr/microservices-datadriven/cloudbank-v4/customer/target/customer-0.0.1-SNAPSHOT.jar

artifact create --namespace application --workload creditscore --imageVersion 0.0.1 --file /Users/devusr/microservices-datadriven/cloudbank-v4/creditscore/target/creditscore-0.0.1-SNAPSHOT.jar

artifact create --namespace application --workload transfer --imageVersion 0.0.1 --file /Users/devusr/microservices-datadriven/cloudbank-v4/transfer/target/transfer-0.0.1-SNAPSHOT.jar
```
Create images from the artifacts

The default base image is ghcr.io/oracle/openjdk-image-obaas:21
```
image create --namespace application --workload account --imageVersion 0.0.1

image create --namespace application --workload checks --imageVersion 0.0.1

image create --namespace application --workload customer --imageVersion 0.0.1 

image create --namespace application --workload creditscore --imageVersion 0.0.1 

image create --namespace application --workload transfer --imageVersion 0.0.1 
```

Create a workload for the images
```
workload create --namespace application --imageVersion 0.0.1 --id account --liquibaseDB admin --cpuRequest 100m
workload create --namespace application --imageVersion 0.0.1 --id checks --cpuRequest 100m
workload create --namespace application --imageVersion 0.0.1 --id customer --liquibaseDB admin --cpuRequest 100m
workload create --namespace application --imageVersion 0.0.1 --id creditscore --cpuRequest 100m
workload create --namespace application --imageVersion 0.0.1 --id transfer --cpuRequest 100m
```

Create a binding between the workload and the datastore
```
binding create --namespace application --datastore account --workload account
binding create --namespace application --datastore customer --workload customer
binding create --namespace application --datastore account --workload checks
```

Verify success
```
serverversion
namespace list
datastore list --namespace application
artifact list
image list
binding list --namespace application
workload list --namespace application
```


## Available Commands

### help

Short descriptions for the available commands can be viewed by issuing the `help` command and detailed help for any individual
commands can be viewed by issuing `help [command-name]`. For example:

```bash
oractl:>help
AVAILABLE COMMANDS

Artifact
       artifact list: Lists the artifacts in your platform.
       artifact create: Creates a new artifact in your platform.
       artifact delete: Delete an artifact in your platform.
       artifact deleteByWorkload: Delete an artifact in your platform by workload.

Binding
       binding list: Lists bindings for a given namespace.
       binding update: Update a specific binding for a given namespace.
       binding delete: Delete a specific binding for a given namespace.
       binding create: Create a binding in a given namespace.
       binding get: Get a specific binding for a given namespace.

Built-In Commands
       help: Display help about available commands
       stacktrace: Display the full stacktrace of the last error.
       clear: Clear the shell screen.
       quit, exit: Exit the shell.
       history: Display or save the history of previously run commands
       version: Show version info
       script: Read and execute commands from a file.

Configuration
       configuration delete: Delete a specific configuration key.
       configuration create: Create a configuration.
       configuration get: Get a specific configuration by name.
       configuration update: Update a configuration.
       configuration list: Lists all configuration.

Datastore
       datastore list: Lists datastores for a given namespace.
       datastore update: Update a specific datastore for a given namespace.
       datastore create: Create a datastore in a given namespace.
       datastore delete: Delete a specific datastore for a given namespace.
       datastore get: Get a specific datastore for a given namespace.

Identity
       user list: Lists all the users in your platform.
       user create: Creates a new user in your platform.
       user get: get a user on your platform.
       user delete: Delete a user in your platform.
       user change-roles: Change the roles from the specified user.
       user change-password: Change password for the specified user. 

Image
       image get: Get a specific image on your platform.
       image list: Lists all the images in your platform.
       image create: Creates a new image in your platform.
       image delete: Delete an image in your platform.

Initialization
       connect: Connect to the OBaaS Admin Service.

Namespace
       namespace create: Creates a new namespace in your platform.
       namespace delete: Delete a namespace in your platform.
       namespace update: Update the namespace secrets.
       namespace list: Lists the namespaces in your platform.

Server Version
       serverversion: Get obaas admin server version.

Telemetry
       telemetry-consent update: Update the platforms telemetry consent.
       telemetry-consent list: Lists the platforms telemetry consent status.
       telemetry-consent create: Create a telemetry consent record.

Workload
       autoscaler delete: Delete an autoscaler for a specific workload in a given namespace.
       workload create: Create a workload in a given namespace.
       workload delete: Delete a specific workload for a given namespace.
       workload update: Update a specific workload for a given namespace.
       autoscaler create: Create an autoscaler for a specific workload in a given namespace.
       workload getImage: Get the image for a specific workload in a given namespace.
       workload list: Lists workloads for a given namespace.
       workload get: Get a specific workload for a given namespace.
       autoscaler list: Lists autoscalers for a given workload in a given namespace.
       autoscaler update: Update an autoscaler for a specific workload in a given namespace.


Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

The following is a description of the CLI commands:

## Connect

Use the `connect` command to connect your `oractl` CLI to the Oracle Backend Administration service:

```bash
oractl:>help connect
NAME
       connect - Connect to the OBaaS Spring Cloud admin console.

SYNOPSIS
       connect --url String --help

OPTIONS
       --url String
       admin server URL
       [Optional, default = http://localhost:8080]

       --help or -h
       help for connect
       [Optional]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com

   ```

For example:

```bash
oractl:>connect
? username obaas-admin
? password ****************
obaas-admin -> Welcome!
```

## Artifact

An artifact is Spring microservice JAR file that is uploaded to the platform. 


### artifact create
```bash
oractl:>help artifact create
NAME
       artifact create - Creates a new artifact in your platform.

SYNOPSIS
       artifact create [--namespace String] [--workload String] [--imageVersion String] --nativeImage boolean --path String [--file String] --help 

OPTIONS
       --namespace String
       The namespace the artifact will be created in.
       [Mandatory]

       --workload String
       The workload name for the artifact.
       [Mandatory]

       --imageVersion String
       The version  of the artifact.
       [Mandatory]

       --nativeImage boolean
       Whether to create a native artifact.
       [Optional, default = false]

       --path String
       Artifact Path.
       [Optional]

       --file String
       Jar file used for Artifact Creation.
       [Mandatory]

       --help or -h 
       help for artifact create
       [Optional]

```

   For example:

   ```bash
oractl:>artifact create --namespace myapp --workload account  --imageVersion 1.0.0 --file /Users/devuser/account.jar
obaas-cli [artifact create]: Artifact [account:1.0.0] was successfully created.
   ```

### artifact list
```bash
oractl:>help artifact list
NAME
       artifact list - Lists the artifacts in your platform.

SYNOPSIS
       artifact list --help 

OPTIONS
       --help or -h 
       help for artifact list
       [Optional]

```

   For example:

   ```
   oractl:>artifact list
╔══╤═════════╤════════╤════════╤══════╤══════════════════════════════════════════════════════╗
║ID│Namespace│Workload│Artifact│Native│Path                                                  ║
║  │         │        │Version │Image │                                                      ║
╠══╪═════════╪════════╪════════╪══════╪══════════════════════════════════════════════════════╣
║6 │myapp    │account │1.0.0   │false │/app/upload-dir/myapp/account/target/account-1.0.0.jar║
╚══╧═════════╧════════╧════════╧══════╧══════════════════════════════════════════════════════╝

   ```

### artifact delete
```bash
oractl:>help artifact delete
NAME
       artifact delete - Delete an artifact in your platform.

SYNOPSIS
       artifact delete [--artifactId String] --help 

OPTIONS
       --artifactId String
       The ID of the artifact you want to delete.
       [Mandatory]

       --help or -h 
       help for artifact delete
       [Optional]
```

For example:

```
oractl:>artifact delete --artifactId 6
obaas-cli [artifact delete]: Artifact [6] was successfully deleted.
```

### artifact deleteByWorkload
```bash
oractl:>help artifact deleteByWorkload
NAME
       artifact deleteByWorkload - Delete an artifact in your platform by workload.

SYNOPSIS
       artifact deleteByWorkload [--namespace String] [--workload String] [--artifactVersion String] --help 

OPTIONS
       --namespace String
       The namespace the artifact will be deleted in.
       [Mandatory]

       --workload String
       The workload name for the artifact.
       [Mandatory]

       --artifactVersion String
       The version  of the artifact.
       [Mandatory]

       --help or -h 
       help for artifact deleteByWorkload
       [Optional]

```

For example:
```
oractl:>artifact deleteByWorkload --namespace myapp --workload account --artifactVersion 1.0.0
obaas-cli [artifact delete]: Artifact [account:1.0.0] was successfully deleted.
```


## Binding

A binding liks the datastore to a workload.

# ALL BELOW IS FROM PREVIOUS AND WILL BE DELETED
# EXCEPT FOR LOGGING


> ATTENTION: Ensure that you want to completely delete the application namespace. You cannot rollback the components once deleted.

```bash
NAME
       delete - Delete a service or entire application/namespace.

SYNOPSIS
       delete --app-name String --service-name String --image-version String --help

OPTIONS
       --app-name String
       application/namespace
       [Optional]

       --service-name String
       Service Name
       [Optional]

       --image-version String
       Image Version
       [Optional]

       --help or -h
       help for delete
       [Optional]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

   For example:

   ```bash
   oractl:>delete --app-name myapp

   obaas-cli [delete]: The Application/Namespace [myapp] will be removed, including all Services deployed. Do you confirm the complete deletion (y/n)?: y
   
   obaas-cli [delete]: Application/Namespace [myapp] as successfully deleted
   ```

### bind

Use the `bind` command to create and update a database schema or user for the service. These commands also create or update the Kubernetes secret and binding environment entries for the schema. These are set in the Kubernetes deployment created with the `deploy` command. For example:

```bash
oractl:>help bind
NAME
       bind - Create or Update a schema/user and bind it to service deployment.

SYNOPSIS
       bind --action CommandConstants.BindActions --app-name String --service-name String 
       --username String --binding-prefix String --help

OPTIONS
       --action CommandConstants.BindActions
       possible actions: create or update. create is default.
       [Optional, default = create]

       --app-name String
       application/namespace
       [Optional, default = application]

       --service-name String
       Service Name (Default for database user if username is not provided)
       [Optional]

       --username String
       Database User
       [Optional]

       --binding-prefix String
       spring binding prefix
       [Optional, default = spring.datasource]

       --help or -h
       help for bind
       [Optional]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

   > ATTENTION: The `service-name` is mandatory and used as the name for the schema or user to be created. If you want to use a different schema or user from the `service-name`, you must also submit the `username`.

   1. Use the `bind` or `bind create` command to **create** a database schema or user for the service. For Example:

       ```bash
       oractl:>bind create --app-name myapp --service-name myserv
       Database/Service Password: ************
       Schema {myserv} was successfully created and Kubernetes Secret {myapp/myserv} was successfully created.
       ```

   1. Use the `bind update` command to **update** an already created database schema or user for the service. For example:

       ```cmd
       oractl:>bind update --app-name myapp --service-name myserv
       Database/Service Password: ************
       Schema {myserv} was successfully updated and Kubernetes Secret {myapp/myserv} was successfully updated.
       ```

### deploy

Use the `deploy` command to create, build, and push an image for the microservice and create the necessary deployment, service, and secret Kubernetes resources for the microservice.

```bash
oractl:>help deploy
NAME
       deploy - Deploy a service.

SYNOPSIS
       deploy --bind String --app-name String [--service-name String] [--image-version String] 
       --service-profile String --port String --java-version String --add-health-probe boolean 
       --liquibase-db String [--artifact-path String] --initial-replicas int 
       --graalvm-native boolean --apigw boolean --route String --apikey String --help

OPTIONS
       --bind String
       automatically create and bind resources. possible values are [jms]
       [Optional]

       --app-name String
       application/namespace
       [Optional, default = application]

       --service-name String
       Service Name
       [Mandatory]

       --image-version String
       Image Version
       [Mandatory]

       --service-profile String
       Service Profile
       [Optional]

       --port String
       Service Port
       [Optional, default = 8080]

       --java-version String
       Java Base Image [ghcr.io/graalvm/jdk:ol9-java17-22.3.1]
       [Optional]

       --add-health-probe boolean
       Inject or not Health probes to service.
       [Optional, default = false]

       --liquibase-db String
       Inform the database name for Liquibase.
       [Optional]

       --artifact-path String
       Service jar/exe location
       [Mandatory]

       --initial-replicas int
       The initial number of replicas
       [Optional, default = 1]

       --graalvm-native boolean
       Artifact is a graalvm native compiled by Oracle Backend
       [Optional, default = false]

       --apigw boolean
       open routing through APISIX
       [Optional, default = false]

       --route String
       set an APISIX route path
       [Optional, default = /api/v1/]

       --apikey String
       set APISIX API_KEY
       [Optional]

       --help or -h
       help for deploy
       [Optional]



CURRENTLY UNAVAILABLE
       you are not signedIn. Please sign in to be able to use this command!

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

   For example:

   ```bash
   oractl:>deploy --app-name myapp --service-name myserv --image-version 0.0.1 --port 8081
       --bind jms --add-health-probe true --artifact-path obaas/myserv/target/demo-0.0.1-SNAPSHOT.jar
   uploading: obaas/myserv/target/demo-0.0.1-SNAPSHOT.jar building and pushing image...
   binding resources... successful
   creating deployment and service... successfully deployed
   ```

   or, for native compiled microservices, add **--java-version container-registry.oracle.com/os/oraclelinux:7-slim** to have a compact image and **--graalvm-native** to specify the file provided is an executable .exec:

   ```bash
   oractl:>deploy --app-name myapp --service-name account 
     --artifact-path obaas/myserv/target/accounts-0.0.1-SNAPSHOT.jar.exec --image-version 0.0.1 
     --graalvm-native --java-version container-registry.oracle.com/os/oraclelinux:7-slim
   ```

### create-autoscaler

Use the `create-autoscaler` command to create a horizontal pod autoscaler for a microservice you have deployed.  You can specify the target scaling threshold using CPU percentage.  Note that your microservice must have its CPU request set in order to use the autoscaler.  It is set to `500m` (that is, half a core) by the `deploy` command if you did not override the default.

```bash
oractl:>help create-autoscaler
NAME
       create-autoscaler - Create an autoscaler.

SYNOPSIS
       create-autoscaler --app-name String [--service-name String] --min-replicas int 
         --max-replicas int --cpu-request String --cpu-percent int --help

OPTIONS
       --app-name String
       application/namespace
       [Optional, default = application]

       --service-name String
       Service Name
       [Mandatory]

       --min-replicas int
       The minimium number of replicas
       [Optional, default = 1]

       --max-replicas int
       The maximum number of replicas
       [Optional, default = 4]

       --cpu-request String
       The amount of CPU to request
       [Optional, default = 100m]

       --cpu-percent int
       The CPU percent at which to scale
       [Optional, default = 80]

       --help or -h
       help for create-autoscaler
       [Optional]



CURRENTLY UNAVAILABLE
       you are not signedIn. Please sign in to be able to use this command!

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example:

```bash
oractl:>create-autoscaler --app-name application --service-name creditscore --cpu-percent 80 
  --cpu-request 200m --min-replicas 2 --max-replicas 6
obaas-cli [create-autoscaler]: Autoscaler was successfully created.
```

You can view the details of the autoscaler using `kubectl`, for example:

```bash
$ kubectl -n application get hpa
NAME          REFERENCE                TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
creditscore   Deployment/creditscore   0%/80%    2         6         2          26s
customer      Deployment/customer      4%/80%    2         6         2          26h

```

### delete-autoscaler

Use the `delete-autoscaler` command to delete a horizontal pod autoscaler for a microservice you have deployed.

```bash
oractl:>help delete-autoscaler
NAME
       delete-autoscaler - Delete an autoscaler.

SYNOPSIS
       delete-autoscaler --app-name String [--service-name String] --help

OPTIONS
       --app-name String
       application/namespace
       [Optional, default = application]

       --service-name String
       Service Name
       [Mandatory]

       --help or -h
       help for delete-autoscaler
       [Optional]


Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example:

```bash
oractl:>delete-autoscaler --app-name application --service-name creditscore
obaas-cli [delete-autoscaler]: Autoscaler was successfully deleted.
```

### list

Use the `list` command to show details of the microservice deployed in the previous step. For example:

```bash
oractl:>help list
NAME
       list - list/show details of application services.

SYNOPSIS
       list --app-name String --help

OPTIONS
       --app-name String
       application/namespace
       [Optional, default = application]

       --help or -h
       help for list
       [Optional]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example:

```bash
   oractl:>list --app-name myapp
   name:myserv-c46688645-r6lhl  status:class V1ContainerStatus {
       containerID: cri-o://6d10194c5058a8cf7ecbd5e745cebd5e44c5768c7df73053fa85f54af4b352b2
       image: <region>.ocir.io/<tenancy>/obaas03/myapp-myserv:0.0.1
       imageID: <region>.ocir.io/<tenancy>/obaas03/myapp-myserv@sha256:99d4bbe42ceef97497105218594ea19a9e9869c75f48bdfdc1a2f2aec33b503c
       lastState: class V1ContainerState {
           running: null
           terminated: null
           waiting: null
       }
       name: myserv
       ready: true
       restartCount: 0
       started: true
       state: class V1ContainerState {
           running: class V1ContainerStateRunning {
               startedAt: 2023-04-13T01:00:51Z
           }
           terminated: null
           waiting: null
       }
   }name:myserv  kind:null
```

### config

Use the `config` command to view and update the configuration managed by the Spring Cloud Config server. More information about the configuration server can be found at this link: [Spring Config Server](../../platform/config/)

```bash
oractl:>help config
NAME
       config - View and modify Service configuration.

SYNOPSIS
       config [--action CommandConstants.ConfigActions] --service-name String --service-label String 
       --service-profile String --property-key String --property-value String --artifact-path String --help

OPTIONS
       --action CommandConstants.ConfigActions
       possible actions: add, list, update, or delete
       [Mandatory]

       --service-name String
       Service Name
       [Optional]

       --service-label String
       label for config
       [Optional]

       --service-profile String
       Service Profile
       [Optional]

       --property-key String
       the property key for the config
       [Optional]

       --property-value String
       the value for the config
       [Optional]

       --artifact-path String
       the context
       [Optional]

       --help or -h
       help for config
       [Optional]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

   1. Use the `config add` command to add the application configuration to the Spring Cloud Config server using one of the two following options:

      * Add a specific configuration using the set of parameters `--service-name`, `--service-label`, `--service-profile`, `--property-key`, and `--property-value`. For example:

       ```bash
       oractl:>config add --service-name myserv --service-label 0.0.1 --service-profile default
         --property-key k1 --property-value value1
       Property added successfully.
       ```

      * Add a set of configurations based on a configuration file using these commands:

       ```json
       {
       "application": "myserv",
       "profile": "obaas",
       "label": "0.0.1",
       "properties": {
              "spring.datasource.driver-class-name": "oracle.jdbc.OracleDriver",
              "spring.datasource.url": "jdbc:oracle:thin:@$(db.service)?TNS_ADMIN=/oracle/tnsadmin"
       }
       }
       ```

       ```bash
       oractl:>config add --artifact-path /obaas/myserv-properties.json
       2 property(s) added successfully.
       oractl:>config list --service-name myserv --service-profile obaas --service-label 0.0.1
       [ {
              "id" : 222,
              "application" : "myserv",
              "profile" : "obaas",
              "label" : "0.0.1",
              "propKey" : "spring.datasource.driver-class-name",
              "value" : "oracle.jdbc.OracleDriver",
              "createdOn" : "2023-04-13T01:29:38.000+00:00",
              "createdBy" : "CONFIGSERVER"
       }, {
              "id" : 223,
              "application" : "myserv",
              "profile" : "obaas",
              "label" : "0.0.1",
              "propKey" : "spring.datasource.url",
              "value" : "jdbc:oracle:thin:@$(db.service)?TNS_ADMIN=/oracle/tnsadmin",
              "createdOn" : "2023-04-13T01:29:38.000+00:00",
              "createdBy" : "CONFIGSERVER"
       } ]
       ```

   1. Use the `config list` command, without any parameters, to list the services that have at least one configuration inserted in the Spring Cloud Config server. For example:

       ```bash
       oractl:>config list
       [ {
       "name" : "apptest",
       "label" : "",
       "profile" : ""
       }, {
       "name" : "myapp",
       "label" : "",
       "profile" : ""
       }, […]

       ```

   1. Use the `config list [parameters]` command to list the parameters using parameters as filters. For example:

       * `--service-name` : Lists all of the parameters from the specified service.
       * `--service-label` : Filters by label.
       * `--service-profile` : Filters by profile.
       * `--property-key` : Lists a specific parameter filter by key.

       For example:

       ```bash
       oractl:>config list --service-name myserv --service-profile default --service-label 0.0.1
       [ {
       "id" : 221,
       "application" : "myserv",
       "profile" : "default",
       "label" : "0.0.1",
       "propKey" : "k1",
       "value" : "value1",
       "createdOn" : "2023-04-13T01:10:16.000+00:00",
       "createdBy" : "CONFIGSERVER"
       } ]
       ```

   1. Use the `config update` command to update a specific configuration using the set of parameters:

       * `--service-name`
       * `--service-label`
       * `--service-profile`
       * `--property-key`
       * `--property-value`

       For example:

       ```bash
       oractl:>config list --service-name myserv --service-profile obaas --service-label 0.1 --property-key k1
       [ {
       "id" : 30,
       "application" : "myserv",
       "profile" : "obaas",
       "label" : "0.1",
       "propKey" : "k1",
       "value" : "value1",
       "createdOn" : "2023-03-23T18:02:29.000+00:00",
       "createdBy" : "CONFIGSERVER"
       } ]

       oractl:>config update --service-name myserv --service-profile obaas --service-label 0.1 --property-key k1 --property-value value1Updated
       Property successful modified.

       oractl:>config list --service-name myserv --service-profile obaas --service-label 0.1 --property-key k1
       [ {
       "id" : 30,
       "application" : "myserv",
       "profile" : "obaas",
       "label" : "0.1",
       "propKey" : "k1",
       "value" : "value1Updated",
       "createdOn" : "2023-03-23T18:02:29.000+00:00",
       "createdBy" : "CONFIGSERVER"
       } ]
       ```

   1. Use the `config delete` command to delete the application configuration from the Spring Cloud Config server using one of the following two options:

      1. Delete all configurations from a specific service using the filters `--service-name`, `--service-profile` and `--service-label`. The
       CLI tracks how many configurations are present in the Spring Cloud Config server and confirms the completed deletion. For example:

         ```bash
         oractl:>config delete --service-name myserv
         [obaas] 7 property(ies) found, delete all (y/n)?:
         ```

      1. Delete a specific configuration using the parameters `--service-name`, `--service-label`, `--service-profile` and `--property-key`. For example:

         ```bash
         oractl:>config list --service-name myserv --service-profile obaas --service-label 0.1 --property-key ktest2
         [ {
                "id" : 224,
                "application" : "myserv",
                "profile" : "obaas",
                "label" : "0.1",
                "propKey" : "ktest2",
                "value" : "value2",
                "createdOn" : "2023-04-13T01:52:11.000+00:00",
                "createdBy" : "CONFIGSERVER"
         } ]
       
         oractl:>config delete --service-name myserv --service-profile obaas --service-label 0.1 --property-key ktest2
         [obaas] property successfully deleted.
       
         oractl:>config list --service-name myserv --service-profile obaas --service-label 0.1 --property-key ktest2
         400 : "Couldn't find any property for submitted query."
         ```

### compile

Use the `GraalVM Compile Commands` to:

* Upload a **.jar** file to the Oracle Backend for Microservices and AI and its GraalVM compiler service.
* Start a compilation of your microservice to produce an executable native **.exec** file.
* Retrieve the last logs available regarding a compilation in progress or terminated.
* Download the **.exec** file to deploy on the backend.
* Purge the files remaining after a compilation on the remote GraalVM compiler service.

The GraalVM Compile Commands are the following:

```bash
oractl:>help 
   
GraalVM Compile Commands
       compile-download: Download the compiled executable file.
       compile: Compile a service with GraalVM.
       compile-purge: Delete a launched job.
       compile-logs: Compilation progress.
```

1. Use the `compile` command to upload and automatically start compilation using the following command:

    ```bash
    oractl:>help compile
    NAME
        compile - Compile a service with GraalVM

    SYNOPSIS
        compile [--artifact-path String] --help

    OPTIONS
        --artifact-path String
        Service jar to compile location
        [Mandatory]

        --help or -h
        help for compile
        [Optional]


    Ask for Help
        Slack: https://oracledevs.slack.com/archives/C03ALDSV272
        E-mail: obaas_ww@oracle.com
    ```

    Because the compilation of a **.jar** file using the tool `native-image` does not support cross-compilation, it must be on the same platform where the application will run. This service guarantees a compilation in the same operating system and CPU type where the service will be executed on the Kubernetes cluster.

    The Spring Boot application **pom.xml** with the plugin:

    ```xml
    <plugin>
        <groupId>org.graalvm.buildtools</groupId>
        <artifactId>native-maven-plugin</artifactId>
    </plugin>
    ```

    The project should be compiled on the developer desktop with GraalVM version 22.3 or later using an **mvn** command. For example:

    ```bash
    mvn -Pnative native:compile -Dmaven.test.skip=true
    ```

    This pre-compilation on your desktop checks if there are any issues on the libraries used in your Spring Boot microservice. In addition, your executable **.jar** file must include ahead-of-time (AOT) generated assets such as generated classes and JSON hint files. For additional information, see [Converting Spring Boot Executable Jar](https://docs.spring.io/spring-boot/docs/current/reference/html/native-image.html#native-image.advanced.converting-executable-jars).

    The following is an example of the command output:

    ```bash
    oractl:>compile --artifact-path /Users/cdebari/demo-0.0.1-SNAPSHOT.jar
    uploading: /Users/cdebari/demo-0.0.1-SNAPSHOT.jar
    filename: demo-0.0.1-SNAPSHOT.jar
    return: demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b
    return: Shell script execution started on: demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b
    successfully start compilation of: demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b
    oractl:>
    ```

    The following example shows the generated batch ID that must be used to retrieve the log files, download the compiled file, and purge the service instance:

    *demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b*

    If omitted, then the last batch is considered by default.

1. Use the `compile-logs` command to retrieve the logs that show the compilation progress. For example:

    ```bash
    oractl:>help compile-logs
    NAME
        compile-logs - Compilation progress.

    SYNOPSIS
        compile-logs --batch String --help 

    OPTIONS
        --batch String
        File ID returned from the compile command. If not provided by default, then the last file compiled.
        [Optional]

        --help or -h 
        help for compile-logs
        [Optional]

    Ask for Help
        Slack: https://oracledevs.slack.com/archives/C03ALDSV272
        E-mail: obaas_ww@oracle.com
    ```

    As previously mentioned, if the batch ID is not provided, then the logs of the most recently executed compilation are returned. For example:

    ```bash
    oractl:>compile-logs

    extracted: BOOT-INF/lib/spring-jcl-6.0.11.jar
    extracted: BOOT-INF/lib/spring-boot-jarmode-layertools-3.1.2.jar
    inflated: BOOT-INF/classpath.idx
    inflated: BOOT-INF/layers.idx
    ========================================================================================================================
    GraalVM Native Image: Generating 'demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b.exec' (executable)...
    ========================================================================================================================
    For detailed information and explanations on the build output, visit:
    https://github.com/oracle/graal/blob/master/docs/reference-manual/native-image/BuildOutput.md
    ------------------------------------------------------------------------------------------------------------------------
    ```

    If the `compile-logs` commands returns a **Finished generating** message, then download the **.exec** file. For example:

    ```bash
    CPU:  Enable more CPU features with '-march=native' for improved performance.
    QBM:  Use the quick build mode ('-Ob') to speed up builds during development.
    ------------------------------------------------------------------------------------------------------------------------
                    155.3s (8.2% of total time) in 169 GCs | Peak RSS: 5.34GB | CPU load: 0.70
    ------------------------------------------------------------------------------------------------------------------------
    Produced artifacts:
    /uploads/demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b.temp/demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b.exec (executable)
    ========================================================================================================================
    Finished generating 'demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b.exec' in 31m 30s.
    Compiling Complete.
    ```

1. Use the `compile-download` command to download the generated **.exec** file. For example:

    ```bash
    oractl:>help compile-download
        NAME
        compile-download - Download the compiled executable file.

        SYNOPSIS
        compile-download --batch String --help 

        OPTIONS
        --batch String
        File ID to download as the executable file. If not provided by default, then the last file compiled.
        [Optional]

        --help or -h 
        help for compile-download
        [Optional]

    Ask for Help
        Slack: https://oracledevs.slack.com/archives/C03ALDSV272
        E-mail: obaas_ww@oracle.com
    ```

    You can choose to use the batch ID if you need the last file compiled. The following example specifies the batch ID:

    ```bash
    oractl:>compile-download --batch demo-0.0.1-SNAPSHOT.jar_24428206-7d71-423f-8ef5-7d779977535b

    File downloaded successfully to: 
    /Users/cdebari/demo-0.0.1-SNAPSHOT.jar.exec
    ```

1. Use the `compile-purge` command to delete all of the artifacts generated on the GraalVM compiler service after downloading the **.exec** file:

    ```bash
    oractl:>help compile-purge
    NAME
        compile-purge - Delete a launched job.

    SYNOPSIS
        compile-purge --batch String --help 

    OPTIONS
        --batch String
        File ID returned from compile command. If not provided by default, then the last file compiled.
        [Optional]

        --help or -h 
        help for compile-purge   
        [Optional]

    Ask for Help
        Slack: https://oracledevs.slack.com/archives/C03ALDSV272
        E-mail: obaas_ww@oracle.com
    ```

### User Management

Manage users allows you to create the platform users and assign the roles that give access permission to operate with the platform.

**User Roles**

* `ROLE_USER`: Users with this role can:
  * Connect to the Admin Service.
  * Create and list applications (namespaces).
  * Create and update a database schema for the service.
  * Deploy, list, and scale workloads (services).

* `ROLE_ADMIN`: Users with this role have the same access rights as a `ROLE_USER` and additionally:
  * Create and delete users.
  * Search for users.
  * Change password and roles for users.

* `ROLE_CONFIG_EDITOR`: Users with this role are allowed to edit the platform configurations. **Reserved for future use**.

#### Create users

Use the `user create` command to add users to the platform. This command requires the name of the user `username` and the user roles in a comma-separated list.

```text
oractl:>help user create
NAME
       user create - Creates a new user in your platform.

SYNOPSIS
       user create [--username String] --roles String --help

OPTIONS
       --username String
       The name you assign to the user during creation. This is the user's login for the CLI and for the SOC UI, also. The name must be unique across all users in the platform and cannot be changed.
       [Mandatory]

       --roles String
       The user's role within the platform. A user must have up to three possible roles provided in a comma-separated list. [ROLE_ADMIN,ROLE_CONFIG_EDITOR,ROLE_USER].
       [Optional, default = ROLE_USER]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example, to create a user called `obaas-user-test1` with roles `ROLE_USER,ROLE_CONFIG_EDITOR`:

```bash
oractl:>user create --username obaas-user-test1 --roles ROLE_USER,ROLE_CONFIG_EDITOR
? password ****************
obaas-cli [user create]: User [obaas-user-test1] as successfully created.
```

#### Obtain User details

Use the `user get` command to obtain the user details registered on the platform.

```bash
oractl:>help user get
NAME
       user get - Gets the specified user’s information.

SYNOPSIS
       user get [--username String] --help

OPTIONS
       --username String
       The username of the user.
       [Mandatory]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example, to list the details from the user called `obaas-admin`:

```bash
oractl:>user get --username obaas-admin
╔══╤═══════════╤═══════════════════════════════════════╗
║Id│Username   │Roles                                  ║
╠══╪═══════════╪═══════════════════════════════════════╣
║2 │obaas-admin│ROLE_ADMIN,ROLE_CONFIG_EDITOR,ROLE_USER║
╚══╧═══════════╧═══════════════════════════════════════╝
```

#### Change User Roles

Use the `user change-roles` command to change the roles from a specific user registered on the platform.

```bash
oractl:>help user change-roles
NAME
       user change-roles - Change the roles from the specified user.

SYNOPSIS
       user change-roles [--username String] --roles String --help

OPTIONS
       --username String
       The name you assign to the user during creation. This is the user’s login for the CLI.
       [Mandatory]

       --roles String
       The user's role within the platform. A user must have up to three possible roles provided in a comma-separated list. [ROLE_ADMIN,ROLE_CONFIG_EDITOR,ROLE_USER].
       [Optional, default = ROLE_USER]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example, to change the roles from a user called `obaas-user-test1` apply the role `ROLE_USER`:

```bash
oractl:>user change-roles --username obaas-user-test1 --roles ROLE_USER
obaas-cli [user change-roles]: User [obaas-user-test1] roles were successfully updated.
```

#### Change User Password

Use the `user change-password` command to change the password from a specific user registered on the platform. A user is allowed to change its password only. Only users with ROLE_ADMIN can change passwords from other users.

```bash
oractl:>help user change-password
NAME
       user change-password - Change password for the specified user.

SYNOPSIS
       user change-password [--username String] --help

OPTIONS
       --username String
       The username you want to change the password.
       [Mandatory]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example, to change the password from a user called `obaas-user-test1`:

```bash
oractl:>user change-password --username obaas-user-test1
? password ***********
obaas-cli [user change-password]: User [obaas-user-test1] password was successfully updated.
```

#### List Users

Use the `user list` command to obtain the list of users registered on the platform.

```bash
oractl:>help user list
NAME
       user list - Lists the users in your platform.

SYNOPSIS
       user list --help

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example, to list all registered users:

```bash
oractl:>user list
╔══╤════════════════╤═══════════════════════════════════════╗
║Id│Username        │Roles                                  ║
╠══╪════════════════╪═══════════════════════════════════════╣
║1 │obaas-user      │ROLE_USER                              ║
╟──┼────────────────┼───────────────────────────────────────╢
║2 │obaas-admin     │ROLE_ADMIN,ROLE_CONFIG_EDITOR,ROLE_USER║
╟──┼────────────────┼───────────────────────────────────────╢
║3 │obaas-config    │ROLE_CONFIG_EDITOR,ROLE_USER           ║
╟──┼────────────────┼───────────────────────────────────────╢
║4 │obaas-user-test1│ROLE_USER                              ║
╚══╧════════════════╧═══════════════════════════════════════╝
```

#### Delete User

Use the `user delete` command to remove users from the platform.

> NOTE: User deletion is permanent and irreversible.

```bash
oractl:>help user delete
NAME
       user delete - Delete a user in your platform.

SYNOPSIS
       user delete [--username String] --id int --help

OPTIONS
       --username String
       The username you want to delete.
       [Mandatory]

       --id int
       The user id from the user you want to delete.
       [Optional, default = 0]

Ask for Help
       Slack: https://oracledevs.slack.com/archives/C03ALDSV272
       E-mail: obaas_ww@oracle.com
```

For example, to delete a user called `obaas-user-test1`:

```bash
oractl:>user delete --username obaas-user-test1
obaas-cli [user delete]: User [obaas-user-test1] as successfully deleted.
````

## Get Passwords

Commands to get the various systme generated passwords

## Logging

The log file for `oractl` on Mac or Unix machine is stored in the `$HOME/config/orctl` directory. The file name is `oractl-cli-history.log`
