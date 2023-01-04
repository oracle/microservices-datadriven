---
title: Using the CLI
---

## Setup

The Oracle Backend as a Service for Spring Cloud command-line tool, `obaas`, is available for Linux and Mac systems.
Download the binary you want from the [Releases](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0) page
and add it to your PATH environment variable.  You may like to rename the binary to remove the suffix.

If you're environment is a Linux or Mac machine you need to execute `chmod +x` on the downloaded binary. Also if your environment is a Mac you need execute the following command `sudo xattr -r -d com.apple.quarantine <downloaded-file>` otherwise will you get a security warning and the CLI will not work.

### Using the CLI

1. Expose the Oracle Spring Cloud Admin Server that the CLI will call by using `port-forward`

    ```shell
    kubectl port-forward services/obaas-admin -n obaas-admin  8080:8080
    ```

2. Start the CLI in interactive mode by simply running `obaas` from your terminal window.

```shell
    obaas
```

The CLI commands simplify the deployment of applications containing microservices as well as bindings with the resources they use.

Short descriptions of the available commands are as follows.

## AVAILABLE COMMANDS

Admin Server Commands
   - `change-password`: change password for Oracle Spring
connect: connect to the Oracle Spring admin console

Application/Namespace Commands
   - `create`: create an application/namespace
   - `delete`: delete a service or entire application/namespace

Built-In Commands
   - `help`: Display help about available commands
   - `stacktrace`: Display the full stacktrace of the last error.
   - `clear`: Clear the shell screen.
   - `quit`, `exit`: Exit the shell.
   - `history`: Display or save the history of previously run commands
   - `version`: Show version info
   - `script`: Read and execute commands from a file.

Informational Commands
   - `list`: list/show details of application services

Service Commands
   - `bind`: create a schema/user and bind it to service deployment
   - `config`: view and modify application configuration
   - `deploy`: deploy a service

An application is a namespace encompassing related microservices. For example, a "cloudbank" application may have "banktransfer", "frauddetection", etc. microservices deployed within it.
The `create` command results in the creation of an application namespace.

The `bind` command results in the automatic creation of a database schema for a given service/user and binds the information for that schema/database in the environment of the microservice for it to use.  The option of the prefix for the environment properties bound is also given.  For example, most Spring microservices us "spring.datasource".

The `deploy` command takes `serviceName`, `appName`, and `jarLocation` as it's main arguments (`imageVersion` and `javaVersion` options are also provided).
When the deploy command is issued, the microservice jar file is uploaded to the backend, a Docker image is created for the jar/microservice, and various Kubernetes resources such as deployment, service, etc. are also created.  
This is all done automatically to simplify the development process and the management of the microservices by the backend.

The `list` command can then be used show the details of the deployed microservice, etc.

The `config` command can also be used to view and update configuration managed by the Spring Config Server.

A common development workflow pattern is to `connect`, `change-password` (only if necessary), `create` (once per app/namespace), `config`, `bind` (only if necessary), `deploy`, and `list`.

Further development and redeployment of the service can then be iterated upon by issuing the `deploy`, `list`, etc. commands.

The following is an example development workflow using the CLI.

First, a connection is made to the Oracle server-side Spring Admin

```cmd
obaas:>help connect
NAME
       connect - connect to the Oracle Spring admin console

SYNOPSIS
       connect --url String --username String

OPTIONS
       --url String
       Spring Cloud admin server URL
       [Optional, default = http://localhost:8080]

       --username String
       Spring Cloud username (will be prompted for password)
       [Optional, default = admin]



obaas:>connect
Spring Cloud password (defaults to oraclespring): 
using default value... 
connect successful server version:121522
```

Then, an application namespace is created withe the `create` command. This namespace will contain the microservices that are deployed later.

```cmd
obaas:>help create
NAME
       create - create an application/namespace

SYNOPSIS
       create --appName String

OPTIONS
       --appName String
       application/namespace
       [Optional, default = cloudbank]



obaas:>create
application/namespace created successfully and image pull secret (registry-auth) created successfully
```

Next, the `bind` command will create a database schema/user for the service (if one hasn't already been created).
The command will also create the Kubernetes secret and binding environment entries for the schema (these will be set in the Kubernetes deployment created with the `deploy` command).

```cmd
obaas:>help bind
NAME
       bind - create a schema/user and bind it to service deployment

SYNOPSIS
       bind --appName String --serviceName String --springBindingPrefix String

OPTIONS
       --appName String
       application/namespace
       [Optional, default = cloudbank]

       --serviceName String
       database user/serviceName
       [Optional, default = bankb]

       --springBindingPrefix String
       spring binding prefix
       [Optional, default = spring.datasource]



obaas:>bind
database password/servicePassword (defaults to Welcome12345): 
using default value... 
schema created successfully for bankb and database secret (bankb-db-secrets) created successfully
```

The microservice jar will now be deployed with the `deploy` command which will create, build, and push an image for the microservice and create the necessary deployment, service, secret, etc. Kubernetes resources for the microservice.

```cmd
obaas:>help deploy
NAME
       deploy - deploy a service

SYNOPSIS
       deploy --isRedeploy String --appName String --serviceName String --jarLocation String --imageVersion String --javaImage String

OPTIONS
       --isRedeploy String
       whether the service has already been deployed or not
       [Optional, default = true]

       --appName String
       application/namespace
       [Optional, default = cloudbank]

       --serviceName String
       service name
       [Optional, default = bankb]

       --jarLocation String
       service jar location
       [Optional, default = target/bankb-0.0.1-SNAPSHOT.jar]

       --imageVersion String
       image version
       [Optional, default = 0.1]

       --javaImage String
       java image
       [Optional, default = ghcr.io/graalvm/jdk:ol7-java17-22.2.0]



obaas:>deploy --jarLocation /Users/pparkins/Downloads/orahub/ora-microservices-dev/ebaas-platform/sample-app/bankb/target/bankb-0.0.1-SNAPSHOT.jar 
uploading... upload successful
building and pushing image... docker build and push successful
creating deployment and service... create deployment and service  = bankb, appName = cloudbank, isRedeploy = true successful
successfully deployed
```

The `list` command can then be used to show details of the microservice deployed in the previous step.

```cmd
obaas:>help list
NAME
       list - list/show details of application services

SYNOPSIS
       list --appName String

OPTIONS
       --appName String
       application/namespace
       [Optional, default = cloudbank]



obaas:>list
name:bankb-5484bc9956-7hqjz  status:class V1ContainerStatus {
    containerID: cri-o://86d55f11b2f52adfsfcd3ab3250090337904272
    image: phx.ocir.io/mytenancy/mynamespace/cloudbank-bankb:0.1
    imageID: phx.ocir.io/mytenancy/mynamespace/cloudbank-bankb@sha256:8badf04308068fbbff122951
    lastState: class V1ContainerState {
        running: null
        terminated: null
        waiting: null
    }
    name: bankb
    ready: true
    restartCount: 0
    started: true
    state: class V1ContainerState {
        running: class V1ContainerStateRunning {
            startedAt: 2023-01-03T03:10:03Z
        }
        terminated: null
        waiting: null
    }
}name:bankb  kind:null
```

The `config` command can be used to view and update config managed by the Spring Config Server.

More information on the configuration server can be found here:

- [Spring Config Server](../../platform/config/)

```cmd
obaas:>help config
NAME
       config - view and modify application configuration

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



obaas:>config --command r
[{"id":1,"application":"cloudbank","profile":"dev","label":"latest","propKey":"test-property","value":"This is the test-property value","createdOn":"2022-12-26T18:42:37.000+00:00","createdBy":"ADMIN"}]
```
