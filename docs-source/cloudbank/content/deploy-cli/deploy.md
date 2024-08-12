+++
archetype = "page"
title = "Deploy CloudBank"
weight = 4
+++



1. Obtain the `obaas-admin` password.

    Execute the following command to get the `obaas-admin` password:

    ```shell
    kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
    ```

1. Start a tunnel to the backend service.

    The Oracle Backend for Spring Boot and Microservices admin service is not exposed outside the Kubernetes cluster by default. Use kubectl to start a port forwarding tunnel to establish a secure connection to the admin service.

    Start a tunnel using this command:

    ```shell
    $ kubectl -n obaas-admin port-forward svc/obaas-admin 8080:8080
    Forwarding from 127.0.0.1:8080 -> 8080
    Forwarding from [::1]:8080 -> 8080
    ```

1. Start the Oracle Backend for Spring Boot and Microservices CLI *oractl*

    Open a new terminal Window or Tab and start the Oracle Backend for Spring Boot and Microservices CLI (*oractl*) using this command:

    ```shell
    $ oractl
     _   _           __    _    ___
    / \ |_)  _.  _. (_    /  |   |
    \_/ |_) (_| (_| __)   \_ |_ _|_
    ========================================================================================
      Application Name: Oracle Backend Platform :: Command Line Interface
      Application Version: (1.2.0)
      :: Spring Boot (v3.3.0) ::

      Ask for help:
      - Slack: https://oracledevs.slack.com/archives/C03ALDSV272
      - email: obaas_ww@oracle.com

    oractl:>
    ```

1. Connect to the Oracle Backend for Spring Boot and Microservices admin service called *obaas-admin*

    Connect to the Oracle Backend for Spring Boot and Microservices admin service using this command. Use thr password you obtained is Step 1.

    ```shell
    oractl> connect
    username: obaas-admin
    password: **************
    Credentials successfully authenticated! obaas-admin -> welcome to OBaaS CLI.
    oractl:>
    ```

1. Deploy CloudBank

    CloudBank will be deployed using a script into the namespace `application`. The script does the following:

    * Executes the `bind` command for the services that requires database access.
    * Deploys the CloudBank services.

    > What happens when you use the oractl CLI **bind** command? When you run the `bind` command, the oractl tool does several things for you:

    * Asks for Database user credentials.
    * Creates or updates a k8s secret with the provided user credentials.
    * Creates a Database Schema with the provided user credentials.

    > What happens when you use the Oracle Backend for Spring Boot and Microservices CLI  (*oractl*) **deploy** command? When you run the `deploy` command, *oractl* does several things for you:

    * Uploads the JAR file to server side
    * Builds a container image and push it to the OCI Registry
    * Inspects the JAR file and looks for bind resources (JMS)
    * Create the microservices deployment descriptor (k8s) with the resources supplied
    * Applies the k8s deployment and create k8s object service to microservice

    The services are using [Liquibase](https://www.liquibase.org/). Liquibase is an open-source database schema change management solution which enables you to manage revisions of your database changes easily. When the service gets deployed the `tables` and sample `data` will be created and inserted by Liquibase. The SQL executed can be found in the source code directories of CloudBank.

    Run the following command to deploy CloudBank. When asked for `Database/Service Password:` enter the password `Welcome1234##`. You need to do this multiple times. **NOTE:** The deployment of CloudBank will take a few minutes.

    ```text
    oractl:>script --file deploy-cmds/deploy-cb-java21.txt
    ```

    The output should look similar to this:

    ```text
    Database/Service Password: *************
    Schema {account} was successfully Created and Kubernetes Secret {application/account} was successfully Created.
    Database/Service Password: *************
    Schema {account} was successfully Not_Modified and Kubernetes Secret {application/checks} was successfully Created.
    Database/Service Password: *************
    Schema {customer} was successfully Created and Kubernetes Secret {application/customer} was successfully Created.
    Database/Service Password: *************
    Schema {account} was successfully Not_Modified and Kubernetes Secret {application/testrunner} was successfully Created.
    uploading: account/target/account-0.0.1-SNAPSHOT.jar
    building and pushing image...

    creating deployment and service...
    obaas-cli [deploy]: Application was successfully deployed.
    NOTICE: service not accessible outside K8S
    uploading: checks/target/checks-0.0.1-SNAPSHOT.jar
    building and pushing image...

    creating deployment and service...
    obaas-cli [deploy]: Application was successfully deployed.
    NOTICE: service not accessible outside K8S
    uploading: customer/target/customer-0.0.1-SNAPSHOT.jar
    building and pushing image...

    creating deployment and service...
    obaas-cli [deploy]: Application was successfully deployed.
    NOTICE: service not accessible outside K8S
    uploading: creditscore/target/creditscore-0.0.1-SNAPSHOT.jar
    building and pushing image...

    creating deployment and service...
    obaas-cli [deploy]: Application was successfully deployed.
    NOTICE: service not accessible outside K8S
    uploading: testrunner/target/testrunner-0.0.1-SNAPSHOT.jar
    building and pushing image...

    creating deployment and service...
    obaas-cli [deploy]: Application was successfully deployed.
    NOTICE: service not accessible outside K8S
    uploading: transfer/target/transfer-0.0.1-SNAPSHOT.jar
    building and pushing image...

    creating deployment and service...
    obaas-cli [deploy]: Application was successfully deployed.
    NOTICE: service not accessible outside K8S
    ```
