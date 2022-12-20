---
title: Using the CLI
resources:
  - name: oci-cloud-shell
    src: "oci-cloud-shell.png"
    title: "OCI Cloud Shell icon"
---

## Setup

The Oracle Backend as a Service for Spring Cloud command-line tool, `oracle-spring`, is available for Linux and Mac systems.
Download the binary you want from the [Releases](https://github.com/OBaaS/OBaaS/releases/) page and add it to your PATH environment
variable.

### Usage information

To start the CLI in interactive mode, run `oracle-spring` commands from your terminal window.

```shell
oracle-spring
```

A set of commands will simplify the installation of the application and bindings with the BaaS infrastructure. Declaring and using a namespace for the application that is then resourced with resource groups deployed in the BaaS platform. Commands are exposed as REST endpoints for IDE and console access and include the following:

1. oracle-spring create -n <app name>

    - Creates namespace
    - (any other init)

2. oracle-spring deploy -n <app name> -s <resource name> -g <resource group name> --jar-path ./target/cloudbank-oracle-sample-0.1.0.jar

    - Containerizes app and maintains in repos
    - Binds all necessary resources such as databases, messaging, etc.
    - Creates services, etc. and deploys app in Kubernetes
    - Creates unified observability for application including end to end metrics, logs, and tracing as well as Grafana dashboard

3. oracle-spring show -n <app name> -s <resource name> -g <resource group name>

    - Show details of app

## AVAILABLE COMMANDS

Built-In Commands
       help: Display help about available commands
       stacktrace: Display the full stacktrace of the last error.
       clear: Clear the shell screen.
       quit, exit: Exit the shell.
       history: Display or save the history of previously run commands
       version: Show version info
       script: Read and execute commands from a file.

Commands
       connect: connect to the Oracle Spring admin console
       change-password: change password for Oracle Spring
       create: create an application/namespace
       create-schema: create a schema/user and bind it to service deployment
       config: view and modify application configuration
       deploy: deploy a service
       list: list/show details of application services
       delete: delete a service or entire application/namespace

The following is an example development workflow using the CLI.

{{< hint type=[warning] icon=gdoc_fire title=NOTE >}}
Note that Oracle Spring Admin console must first be accessible by issuing the following kubectl port-forward command:
kubectl port-forward services/oracle-spring-admin -n  oracle-spring-admin  8080:8080
{{< /hint >}}

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

</br>

```cmd
oracle-spring:>create
appName (defaults to cloudbank): 
using default value... 
application/namespace created successfully and image pull secret (registry-auth) created successfully
```

</br>

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

</br>

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

</br>

```cmd
oracle-spring:>list
appname (defaults to cloudbank): 
using default value... 
name:bankb-7c7c59db96-2tjjm  status:class V1ContainerStatus {
    containerID: cri-o://b82106811515f2226dffb85c82918318059f17f3403d002c52a488a26d94b5ff
    image: iad.ocir.io/maacloud/baasdev/cloudbank/bankb:0.1
    imageID: iad.ocir.io/maacloud/baasdev/cloudbank/bankb@sha256:6b50f2ec2a80100061fe93c48ca9620a44ec01c981520aa0b4a14f60f58513f4
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
            startedAt: 2022-12-16T19:06:21Z
        }
        terminated: null
        waiting: null
    }
}name:bankb  kind:null
```

</br>

```cmd
oracle-spring:>config
command ([c]reate, [r]ead all, [u]pdate, [d]elete): r
[id":1,"application":"atael","profile":"dev","label":"latest","propKey":"test-property","value":"This is the test-property value","createdOn":"2022-12-14T12:42:33.000+00:00","createdBy":"ADMIN”
[…]
```