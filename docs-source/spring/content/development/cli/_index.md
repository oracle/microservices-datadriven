---
title: Using the OBaaS CLI
---

The Oracle Backend for Spring Boot offers a command-line interface (CLI), `oractl`. The CLI commands simplify the deployment of microservices applications as well as bindings with the resources they use.
Download the CLI [here](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0).
The platform specific binary can be renamed to `oractl` for convenience.

## Using the CLI

1. Expose the Oracle Backend for Spring Boot Admin server that the CLI calls using this command:

    ```shell
    kubectl port-forward services/obaas-admin -n obaas-admin  8080:8080
    ```

2. Start the CLI in interactive mode by simply running `oractl` from your terminal window. For example:

    ```shell
    oractl
    ```

## AVAILABLE COMMANDS

Short descriptions of the available commands can be viewed by issuing the `help` command and detailed help for any individual command can be viewed by issuing `help [commandname]`

AVAILABLE COMMANDS

```cmd
oractl:>help
AVAILABLE COMMANDS

Admin Server Commands
       change-password: Change password for OBaaS Spring Cloud admin user.
       connect: Connect to the OBaaS Spring Cloud admin console.

Application/Namespace Commands
       create: Create an application/namespace.
       delete: Delete a service or entire application/namespace.

Built-In Commands
       help: Display help about available commands
       stacktrace: Display the full stacktrace of the last error.
       clear: Clear the shell screen.
       quit, exit: Exit the shell.
       history: Display or save the history of previously run commands
       version: Show version info
       script: Read and execute commands from a file.

Informational Commands
       list: list/show details of application services.

Service Commands
       bind: Create a schema/user and bind it to service deployment.
       config: View and modify application configuration.
       deploy: Deploy a service.

oractl:>
```

An application is a namespace encompassing related microservices. For example, a "cloudbank" application may have "banktransfer" "frauddetection", etc., microservices deployed within it.
The `create` command results in the creation of an application namespace.

The `bind` command results in the automatic creation of a database schema for a given service or user and binds the information for that schema or database in the environment for the microservice.  The option of the prefix for the environment properties bound is also given.  For example, most Spring microservices use "spring.datasource".

The `deploy` command takes `service-name`, `app-name`, and `artifact-path` as the main arguments (`image-version` and `java-version` options are also provided).
When the `deploy` command is issued, the microservice JAR file is uploaded to the backend, and a container image is created for the JAR or microservice, and various Kubernetes resources such as deployment and service are also created.
This is all done automatically to simplify the development process and the management of the microservices by the backend.

The `list` command can then be used show the details of the deployed microservice.

The `config` command can also be used to add, view, update, and delete configurations managed by the Spring Config server.

A common development workflow pattern is to `connect`, `change-password` (only if necessary), `create` (once per application or namespace), `config`, `bind` (only if necessary), `deploy`, and `list`.

Further development and redeployment of the service can then be iterated by issuing the `deploy`, `list`, etc. commands.

The following is an example development workflow using the CLI.

First, a connection is made to the Oracle server-side Spring Admin. For example:

```cmd
oractl:>help connect
NAME
       connect - Connect to the OBaaS Spring Cloud admin console.

SYNOPSIS
       connect --url String --username String

OPTIONS
       --url String
       admin server URL
       [Optional, default = http://localhost:8080]

       --username String
       username (will be prompted for password)
       [Optional, default = admin]

oractl:>connect
password (defaults to oractl):
using default value...
connect successful server version:0.3.0
```

Then, an application namespace is created with the `create` command. This namespace contains the microservices that are deployed later. For example:

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

oractl:>create --app-name myapp
application/namespace created successfully and image pull secret (registry-auth) created successfully and database TNSAdmin/wallet secret created successfully
```

Next, the `bind` command creates a database schema or user for the service (if one has not already been created).
The command also creates the Kubernetes secret and binding environment entries for the schema. These will be set in the Kubernetes deployment created with the `deploy` command. For example:

```cmd
oractl:>help bind
NAME
       bind - Create a schema/user and bind it to service deployment.

SYNOPSIS
       bind --app-name String [--service-name String] --binding-prefix String --help

OPTIONS
       --app-name String
       application/namespace
       [Optional, default = application]

       --service-name String
       Service Name/Database User
       [Mandatory]

       --binding-prefix String
       spring binding prefix
       [Optional, default = spring.datasource]

       --help or -h
       help for bind
       [Optional]


oractl:>bind --app-name myapp --service-name myserv
database password/servicePassword (defaults to Welcome12345): ************
database secret created successfully and schema created successfully for myserv
```

The microservice JAR is now deployed with the `deploy` command which creates, builds, and pushes an image for the microservice and creates the necessary deployment, service, and secret Kubernetes resources for the microservice.

```cmd
oractl:>help deploy
NAME
       deploy - Deploy a service.

SYNOPSIS
       deploy --redeploy boolean --bind String --app-name String [--service-name String] [--image-version String] --service-profile String --port String --java-version String --add-health-probe boolean [--artifact-path String] --help

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
       Java Container Base Image [ghcr.io/graalvm/jdk:ol9-java17-22.3.1]
       [Optional]

       --add-health-probe boolean
       Inject or not Health probes to service.
       [Optional, default = false]

       --artifact-path String
       Service jar location
       [Mandatory]

       --help or -h
       help for deploy
       [Optional]

oractl:>deploy --app-name myapp --service-name myserv --image-version 0.0.1 --port 8081 --bind jms --add-health-probe true --artifact-path obaas/myserv/target/demo-0.0.1-SNAPSHOT.jar
uploading: obaas/myserv/target/demo-0.0.1-SNAPSHOT.jar building and pushing image...
binding resources... successful
creating deployment and service... successfully deployed
```

The `list` command can then be used to show details of the microservice deployed in the previous step. For example:

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

The `config` command can be used to view and update the configuration managed by the Spring Config server.
More information on the configuration server can be found at this link:

- [Spring Config Server](../../platform/config/)

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

The `config add` command adds the application configuration to Spring Config server one of the following two options:

- Add a specific configuration using the set of parameters `--service-name`, `--service-label`, `--service-profile`, `--property-key`, and `--property-value`.

  ```cmd
  oractl:>config add --service-name myserv --service-label 0.0.1 --service-profile default --property-key k1 --property-value value1
  Property added successfully.
  ```

- Add a set of configurations based on a config file using `--artifact-path`. For example: `myserv.json`:

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

The `config list` command without any parameters lists the services that have at least one configuration inserted in the Spring Config server. For example:

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

The `config list [parameters]` can be used to list the parameters and use them as filters:

- `--service-name` : Lists all parameters from the specified service.
- `--service-label`: Filters by label.
- `--service-profile`: Filters by profile.
- `--property-key`: Lists a specific parameter filter by key.

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

The `config update` command updates a specific configuration using this set of parameters:

- `--service-name`
- `--service-label`
- `--service-profile`
- `--property-key`
- `--property-value`

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

The `config delete` command deletes the application configuration from the Spring Config server with one of the following two options:

- Delete all configurations from a specific service using the filters by `--service-name`, `--service-profile` and `--service-label`. The CLI tracks how many configurations are present in the Spring Config server and confirms the complete deletion. For example:

  ```cmd
  oractl:>config delete --service-name myserv
  [obaas] 7 property(ies) found, delete all (y/n)?:
  ```

- Delete a specific configuration using the set of parameters `--service-name`, `--service-label`, `--service-profile` and `--property-key`. For example:

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
