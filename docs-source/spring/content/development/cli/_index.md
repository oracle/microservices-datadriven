---
title: Using the Oracle Spring CLI
---

The Oracle Backend as a Service offer a Spring Cloud command-line tool, `oracle-spring`, to be use. The CLI commands simplify the deployment of applications containing microservices as well as bindings with the resources they use.

## Using the CLI

1. Expose the Oracle Spring Cloud Admin Server that the CLI will call by using `port-forward`

    ```shell
    kubectl port-forward services/oracle-spring-admin -n oracle-spring-admin  8080:8080
    ```

2. Start the CLI in interactive mode by simply running `oracle-spring` from your terminal window.

    ```shell
        oracle-spring
    ```

## AVAILABLE COMMANDS

Short descriptions of the available commands are as follows.

Built-In Commands

- `help`: Display help about available commands
- `stacktrace`: Display the full stacktrace of the last error.
- `clear`: Clear the shell screen.
- `quit`, `exit`: Exit the shell.
- `history`: Display or save the history of previously run commands
- `version`: Show version info
- `script`: Read and execute commands from a file.

Commands

- `connect`: connect to the Oracle Spring admin console
- `change-password`: change password for Oracle Spring
- `create`: create an application/namespace
- `create-schema`: create a schema/user and bind it to service deployment
- `config`: view and modify application configuration
- `deploy`: deploy a service
- `list`: list/show details of application services
- `delete`: delete a service or entire application/namespace

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
oracle-spring:>connect
URL (defaults to http://localhost:8080): 
using default value... 
Username (defaults to admin): 
using default value... 
Password (defaults to oraclespring): 
using default value... 
connect successful server version:121522 client version:121522
```

Then, an application namespace is created withe the `create` command. This namespace will contain the microservices that are deployed later.

```cmd
oracle-spring:>create
appName (defaults to cloudbank): 
using default value... 
application/namespace created successfully and image pull secret (registry-auth) created successfully
```

Next, the `bind` command will create a database schema/user for the service (if one hasn't already been created).
The command will also create the Kubernetes secret and binding environment entries for the schema (these will be set in the Kubernetes deployment created with the `deploy` command).

```cmd
oracle-spring:>bind
appName (defaults to cloudbank): 
using default value... 
database user/serviceName (defaults to bankb): 
using default value... 
database password/servicePassword (defaults to Welcome12345): 
using default value... 
springBindingPrefix (defaults to spring.datasource): 
using default value... 
schema already exists for bankb and database secret (bankb-db-secrets) created successfully
```

The microservice jar will now be deployed with the `deploy` command which will create, build, and push an image for the microservice and create the necessary deployment, service, secret, etc. Kubernetes resources for the microservice.

```cmd
oracle-spring:>deploy
isRedeploy (has already been deployed) (defaults to true): false
serviceName (defaults to bankb): 
using default value... 
appName (defaults to cloudbank): 
using default value... 
jarLocation (defaults to target/bankb-0.0.1-SNAPSHOT.jar): /Users/user/Downloads/sample-app/bankb/target/bankb-0.0.1-SNAPSHOT.jar
imageVersion (defaults to 0.1): 
using default value... 
javaVersion (defaults to 11): 
using default value... 
uploading... upload successful
building and pushing image... docker build and push successful
creating deployment and service... create deployment and service  = bankb, appName = cloudbank, isRedeploy = false successful
successfully deployed
```

The `list` command can then be used to show details of the microservice deployed in the previous step.

```cmd
oracle-spring:>list
appname (defaults to cloudbank): 
using default value... 
name:bankb-7c7c59db96-2tjjm 
    name: bankb
    ready: true
    restartCount: 0
    started: true
```

The `config` command can be used to view and update config managed by the Spring Config Server.
More information on the configuration server can be found here:

- [Spring Config Server](../../platform/config/)

```cmd
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): r
[id":1,"application":"atael","profile":"dev","label":"latest","propKey":"test-property","value":"This is the test-property value","createdOn":"2022-12-14T12:42:33.000+00:00","createdBy":"ADMIN”
[…]
```
