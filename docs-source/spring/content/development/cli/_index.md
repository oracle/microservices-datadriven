---
title: Using the OBaaS CLI
---

The Oracle Backend for Spring Boot offers a command-line tool, `oractl`. The CLI commands simplify the deployment of microservices applications as well as bindings with the resources they use.
Download the CLI [here](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0)
The platform specific binary can be renamed to `oractl` for convenience.

## Using the CLI

1. Expose the Oracle Backend for Spring Boot Admin Server that the CLI will call by using `port-forward`

    ```shell
    kubectl port-forward services/obaas-admin -n obaas-admin  8080:8080
    ```

2. Start the CLI in interactive mode by simply running `oractl` from your terminal window.

    ```shell
        oractl
    ```

## AVAILABLE COMMANDS

Short descriptions of the available commands are as follows. These can be viewed by issuing the `help` command and detailed help for any individual command can be viewed by issuing `help [commandname]`

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

The `bind` command results in the automatic creation of a database schema for a given service/user and binds the information for that schema/database in the environment of the microservice for it to use.  The option of the prefix for the environment properties bound is also given.  For example, most Spring microservices us "spring.datasource".

The `deploy` command takes `serviceName`, `appName`, and `jarLocation` as it's main arguments (`imageVersion` and `javaVersion` options are also provided).
When the deploy command is issued, the microservice JAR file is uploaded to the backend, a container image is created for the JAR/microservice, and various Kubernetes resources such as deployment, service, etc. are also created.
This is all done automatically to simplify the development process and the management of the microservices by the backend.

The `list` command can then be used show the details of the deployed microservice, etc.

The `config` command can also be used to view and update configuration managed by the Spring Config Server.

A common development workflow pattern is to `connect`, `change-password` (only if necessary), `create` (once per app/namespace), `config`, `bind` (only if necessary), `deploy`, and `list`.

Further development and redeployment of the service can then be iterated upon by issuing the `deploy`, `list`, etc. commands.

The following is an example development workflow using the CLI.

First, a connection is made to the Oracle server-side Spring Admin

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
connect successful server version:011223
```

Then, an application namespace is created withe the `create` command. This namespace will contain the microservices that are deployed later.

```cmd
oractl:>help create
NAME
       create - Create an application/namespace.

SYNOPSIS
       create --appName String

OPTIONS
       --appName String
       application/namespace
       [Optional, default = cloudbank]

oractl:>create
application/namespace created successfully and image pull secret (registry-auth) created successfully
```

Next, the `bind` command will create a database schema/user for the service (if one hasn't already been created).
The command will also create the Kubernetes secret and binding environment entries for the schema (these will be set in the Kubernetes deployment created with the `deploy` command).

```cmd
oractl:>help bind
NAME
       bind - Create a schema/user and bind it to service deployment.

SYNOPSIS
       bind --appName String --serviceName String --springBindingPrefix String

OPTIONS
       --appName String
       application/namespace
       [Optional, default = cloudbank]

       --serviceName String
       database user/serviceName
       [Optional, default = banka]

       --springBindingPrefix String
       spring binding prefix
       [Optional, default = spring.datasource]

oractl:>bind
database password/servicePassword (defaults to Welcome12345):
using default value...
database secret created successfully and schema created successfully for banka
```

The microservice JAR will now be deployed with the `deploy` command which will create, build, and push an image for the microservice and create the necessary deployment, service, secret, etc. Kubernetes resources for the microservice.

```cmd
oractl:>help deploy
NAME
       deploy - Deploy a service.

SYNOPSIS
       deploy --isRedeploy String --bind String --appName String --serviceName String --jarLocation String --imageVersion String --javaImage String

OPTIONS
       --isRedeploy String
       whether the service has already been deployed or not
       [Optional, default = true]

       --bind String
       automatically create and bind resources. possible values are [jms]
       [Optional, default = none]

       --appName String
       application/namespace
       [Optional, default = cloudbank]

       --serviceName String
       service name
       [Optional, default = banka]

       --jarLocation String
       service jar location
       [Optional, default = target/banka-0.0.1-SNAPSHOT.jar]

       --imageVersion String
       image version
       [Optional, default = 0.1]

       --javaImage String
       java image
       [Optional, default = ghcr.io/graalvm/jdk:ol7-java17-22.2.0]

oractl:>deploy --isRedeploy false --bind jms --jarLocation ebaas-sample-apps/banka/target/banka-0.0.1-SNAPSHOT.jar
uploading... upload successful
building and pushing image... docker build and push successful
binding resources... successful (no resources found to bind)
creating deployment and service... create deployment and service  = banka, appName = cloudbank, isRedeploy = false successful
successfully deployed
```

The `list` command can then be used to show details of the microservice deployed in the previous step.

```cmd
oractl:>help list
NAME
       list - list/show details of application services.

SYNOPSIS
       list --appName String

OPTIONS
       --appName String
       application/namespace
       [Optional, default = cloudbank]

oractl:>list
name:banka-7fbff59d8c-gt42g  status:class V1ContainerStatus {
    containerID: cri-o://df2ec83b9359dee8aad658bde2d9ba988f7e43ea2a3e7add61c0cd2eeca612af
    image: ams.ocir.io/maacloud/walleye/cloudbank-banka:0.1
    imageID: ams.ocir.io/maacloud/walleye/cloudbank-banka@sha256:d37f889f6f706accd32df0ccff576237b3a15c736d90ee99b7f97f84860c3502
    lastState: class V1ContainerState {
        running: null
        terminated: null
        waiting: null
    }
    name: banka
    ready: true
    restartCount: 0
    started: true
    state: class V1ContainerState {
        running: class V1ContainerStateRunning {
            startedAt: 2023-01-18T15:54:10Z
        }
        terminated: null
        waiting: null
    }
}name:banka  kind:null
```

The `config` command can be used to view and update config managed by the Spring Config Server.
More information on the configuration server can be found here:

- [Spring Config Server](../../platform/config/)

```cmd
oractl:>help config
NAME
       config - View and modify application configuration.

SYNOPSIS
       config --command String --application String --label String --profile String --propKey String --value String

OPTIONS
       --command String
       possible values are [c]reate, [r]ead all, [u]pdate, and [d]elete
       [Optional, default = r]

       --application String
       application/namespace config
       [Optional, default = cloudbank]

       --label String
       label for config
       [Optional, default = test]

       --profile String
       profile for config
       [Optional, default = test]

       --propKey String
       the property key for the config
       [Optional, default = test]

       --value String
       the value for the config
       [Optional, default = test]
       
oractl:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): r
[id":1,"application":"atael","profile":"dev","label":"latest","propKey":"test-property","value":"This is the test-property value","createdOn":"2022-12-14T12:42:33.000+00:00","createdBy":"ADMIN”
[…]
```
