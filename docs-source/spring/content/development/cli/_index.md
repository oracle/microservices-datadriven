---
title: "OBaaS CLI"
---

The Oracle Backend for Spring Boot and Microservices offers a command-line interface (CLI), `oractl`. The CLI commands simplify the deployment of
microservices applications as well as bindings with the resources that they use.
Download the CLI [here](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0).
The platform-specific binary can be renamed to `oractl` for convenience.

## Using the CLI

1. Expose the Oracle Backend for Spring Boot and Microservices Admin server that the CLI calls using this command:

    ```cmd
    kubectl port-forward services/obaas-admin -n obaas-admin 8080:8080
    ```

2. Start the CLI in interactive mode by running `oractl` from your terminal window. For example:

    ```cmd
    oractl
    ```

## Available Commands

Short descriptions for the available commands can be viewed by issuing the `help` command and detailed help for any individual
commands can be viewed by issuing `help [command-name]`. For example:

```cmd
oractl:>help
AVAILABLE COMMANDS

Admin Server Commands
       connect: Connect to the Oracle Backend Administration Service.

Application/Namespace Commands
       create: Create an application/namespace.
       delete: Delete a entire application/namespace or service.       

Built-In Commands
       help: Display help about available commands
       stacktrace: Display the full stacktrace of the last error.
       clear: Clear the shell screen.
       quit, exit: Exit the shell.
       history: Display or save the history of previously run commands
       version: Show version info
       script: Read and execute commands from a file.

GraalVM Compile Commands
       compile-download: Download executable file compiled
       compile: Compile a service with GraalVM
       compile-purge: Delete a job launched
       compile-logs: Compilation progress

Informational Commands
       list: list/show details of application services.

Service Commands
       bind: Create or Update a schema/user and bind it to service deployment.
       config: View and modify Service configuration.
       deploy: Deploy a service.
```

An application is a namespace encompassing related Microservices. For example, a "cloudbank" application may have "banktransfer" and
"frauddetection" Microservices deployed within it.

The `create` command results in the creation of an application namespace (Kubernetes *namespace*). The application namespace provides a mechanism for isolating groups of resources, especially the Microservices.

The `delete` command results in the delete of an application namespace (Kubernetes *namespace*) completely or a specific Microservice. <ins>**Be carefully**</ins> because it is not possible rollback the components deleted.

The `bind` command results in the automatic creation of a database schema for a given service or user and binds the information for that schema or
database in the environment of the Microservice. The option of a prefix for the bound environment properties is also returned. For example, most
Spring Boot Microservices use `spring.datasource`.

The `deploy` command takes `service-name`, `app-name`, and `artifact-path` as the main arguments (`image-version` and `java-version` options are
also provided). When the `deploy` command is issued, the Microservice JAR file is uploaded to the backend and a container image is created for
the JAR or Microservice, and various Kubernetes resources such as **Deployment** and **Service** are also created. This is all done
automatically to simplify the development process and the management of the Microservices by the backend.

The `list` command shows the details of the deployed Microservice.

The `config` command can also be used to add, view, update, and delete configurations managed by the Spring Cloud Config server.

A common development workflow pattern is to `connect`, `change-password` (only if necessary), `create` (once per application or namespace), `config`, `bind` (only if necessary), `deploy`, and `list`.

Further development and redeployment of the service can then be repeated issuing the `deploy` and `list` commands.

The following is an example development workflow using the CLI:

1. Use the `connect` command to connect your `oractl` CLI to the Oracle Backend Administration service:

   ```cmd
   oractl:>help connect
   NAME
         connect - Connect to the OBaaS Spring Cloud admin console.

   SYNOPSIS
          connect --url String

   OPTIONS
          --url String
          admin server URL
          [Optional, default = http://localhost:8080]

   ```

   For example:

   ```cmd
   oractl:>connect
   username: obaas-admin
   password: ********
   obaas-cli: Successful connected.
   ```

2. Use the `create` command to create an application namespace (Kubernetes *namespace*). The application namespace provides a mechanism for isolating groups of resources, especially the Microservices. Names of resources need to be unique within a application namespace, but not across application namespaces.

   ```cmd
   oractl:>help create
   NAME
          create - Create an application/namespace.

   SYNOPSIS
          create [--app-name String] --help

   OPTIONS
          --app-name String
          application/namespace
          [Mandatory]

          --help or -h
          help for create
          [Optional]

   ```

   For example:

   ```cmd
   oractl:>create --app-name myapp
   application/namespace created successfully and image pull secret (registry-auth) created successfully and database TNSAdmin/wallet secret created successfully
   ```


3. Use the `delete` command to delete an application namespace (Kubernetes *namespace*) completely or a specific Microservice inside an application namespace.

    > ATTENTION: <ins>**Be carefully**</ins> because it is not possible rollback the components deleted.

   ```cmd
   oractl:>help delete
   NAME
       delete - Delete a service or entire application/namespace.

   SYNOPSIS
       delete --app-name String --service-name String --image-version String --help

   OPTIONS
       --app-name String
       application/namespace
       [Mandatory]

       --service-name String
       Service Name
       [Optional]

       --image-version String
       Image Version
       [Optional]

       --help or -h
       help for delete
       [Optional]
   ```

   For example:

   ```cmd
   oractl:>delete --app-name myapp

   obaas-cli [delete]: The Application/Namespace [myapp] will be removed, including all Services deployed. Do you confirm the complete deletion (y/n)?: y
   
   obaas-cli [delete]: Application/Namespace [myapp] as successfully deleted
   ```

4. Use the `bind` command to create and update a database schema or user for the service. These commands also create or update the Kubernetes secret and binding environment entries for the schema. These are set in the Kubernetes deployment created with the `deploy` command. For example:

   ```cmd
   oractl:>help bind
   NAME
          bind - Create a schema/user and bind it to service deployment.

   SYNOPSIS
          bind --action CommandConstants.BindActions --app-name String --service-name String --username String --binding-prefix String --help

   OPTIONS
          --action CommandConstants.BindActions
          possible actions: create or update. create is default.
          [Optional, default = create]

          --app-name String
          application/namespace
          [Optional, default = application]

          --service-name String
          Service Name/Database User
          [Mandatory]

          --username String
          Database User
          [Optional]

          --binding-prefix String
          spring binding prefix
          [Optional, default = spring.datasource]

          --help or -h
          help for bind
          [Optional]
   ```

   > ATTENTION: The `service-name` is mandatory and used as the name for the Schema/User to be created. If you want to use a different Schema/User from the `service-name`, you must also submit the`username`.

   1. Use the `bind` or `bind create` command to **create** a database schema or user for the service.

       ```cmd
       oractl:>bind create --app-name myapp --service-name myserv
       Database/Service Password: ************
       Schema {myserv} was successfully created and Kubernetes Secret {myapp/myserv} was successfully created.
       ```

   2. Use the `bind update` command to **update** a already created database schema or user for the service.

       ```cmd
       oractl:>bind update --app-name myapp --service-name myserv
       Database/Service Password: ************
       Schema {myserv} was successfully updated and Kubernetes Secret {myapp/myserv} was successfully updated.
       ```

5. Use the `deploy` command to create, build, and push an image for the Microservice and create the necessary deployment, service,
   and secret Kubernetes resources for the Microservice.

   ```cmd
   oractl:>help deploy
   NAME
          deploy - Deploy a service.

   SYNOPSIS
       deploy --redeploy boolean --bind String --app-name String [--service-name String] [--image-version String] --service-profile String --port String --java-version String --add-health-probe boolean --liquibase-db String [--artifact-path String] --initial-replicas int --graalvm-native boolean --help

   OPTIONS
       --redeploy boolean
       whether the service has already been deployed or not
       [Optional, default = false]

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

       --help or -h
       help for deploy
       [Optional]

   ```

   For example:

   ```cmd
   oractl:>deploy --app-name myapp --service-name myserv --image-version 0.0.1 --port 8081 --bind jms --add-health-probe true --artifact-path obaas/myserv/target/demo-0.0.1-SNAPSHOT.jar
   uploading: obaas/myserv/target/demo-0.0.1-SNAPSHOT.jar building and pushing image...
   binding resources... successful
   creating deployment and service... successfully deployed
   ```

6. Use the `list` command to show details of the Microservice deployed in the previous step. For example:

   ```cmd
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

7. Use the `config` command to view and update the configuration managed by the Spring Cloud Config server. More information about the configuration server can be found at this link: [Spring Config Server](../../platform/config/)

   ```cmd
   oractl:>help config
   NAME
          config - View and modify Service configuration.

   SYNOPSIS
          config [--action CommandConstants.ConfigActions] --service-name String --service-label String --service-profile String --property-key String --property-value String --artifact-path String --help

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
          Application Profile
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

   ```

   1. Use the `config add` command to add the application configuration to the Spring Cloud Config server using one of the two following options:

      * Add a specific configuration using the set of parameters `--service-name`, `--service-label`, `--service-profile`, `--property-key`, and `--property-value`. For example:

       ```cmd
       oractl:>config add --service-name myserv --service-label 0.0.1 --service-profile default --property-key k1 --property-value value1
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

       ```cmd
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

   2. Use the `config list` command, without any parameters, to list the services that have at least one configuration inserted in the Spring Cloud Config server. For example:

       ```cmd
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

   3. Use the `config list [parameters]` command to list the parameters using parameters as filters. For example:

       * `--service-name` : Lists all of the parameters from the specified service.
       * `--service-label` : Filters by label.
       * `--service-profile` : Filters by profile.
       * `--property-key` : Lists a specific parameter filter by key.

       For example:

       ```cmd
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

   4. Use the `config update` command to update a specific configuration using the set of parameters:

       * `--service-name`
       * `--service-label`
       * `--service-profile`
       * `--property-key`
       * `--property-value`

       For example:

       ```cmd
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

   5. Use the `config delete` command to delete the application configuration from the Spring Cloud Config server using one of the following two options:

       * Delete all configurations from a specific service using the filters `--service-name`, `--service-profile` and `--service-label`. The
       CLI tracks how many configurations are present in the Spring Cloud Config server and confirms the completed deletion. For example:

         ```cmd
         oractl:>config delete --service-name myserv
         [obaas] 7 property(ies) found, delete all (y/n)?:
         ```

       * Delete a specific configuration using the parameters `--service-name`, `--service-label`, `--service-profile` and `--property-key`. For example:

         ```cmd
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
