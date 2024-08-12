+++
archetype = "page"
title = "Deploy services"
weight = 10
+++
 

The services are now completed, and you are ready to deploy them to the Oracle Backend for Spring Boot and Microservices.

> **Note**: You already created the Kubernetes secrets necessary for the account service to access the Oracle Autonomous Database in a previous module, and the `transfer` service does not need access to the database. You also created the journal table that is needed by the update account application in the previous module.

1. Build the Account and Transfer applications into JAR files

  To build a JAR file from the Account application, issue this command in the `account` directory.  Then issue the same command from the `transfer` directory to build the Transfer application into a JAR file too.

     ```shell
    $ mvn clean package -DskipTests
    ```

  You will now have a JAR file for each application, as can be seen with this command (the command needs to be executed in the `parent` directory for the Account and Transfer applications):

    ```shell
    $ find . -name \*SNAPSHOT.jar
    ./testrunner/target/testrunner-0.0.1-SNAPSHOT.jar
    ./checks/target/checks-0.0.1-SNAPSHOT.jar
    ./transfer/target/transfer-0.0.1-SNAPSHOT.jar
    ./accounts/target/accounts-0.0.1-SNAPSHOT.jar
    ```

1. Deploy the Account and Transfer applications

  You will now deploy your updated account application and new transfer application to the Oracle Backend for Spring Boot and Microservices using the CLI.  You will deploy into the `application` namespace, and the service names will be `account` and `transfer` respectively.  

  The Oracle Backend for Spring Boot and Microservices admin service is not exposed outside of the Kubernetes cluster by default. Oracle recommends using a **kubectl** port forwarding tunnel to establish a secure connection to the admin service.

  Start a tunnel using this command:

    ```shell
    $ kubectl -n obaas-admin port-forward svc/obaas-admin 8080:8080
    ```
  
  Start the Oracle Backend for Spring Boot and Microservices CLI (*oractl*) in the `parent` directory using this command:

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

  Obtain the `obaas-admin` password by executing this command:

    ```shell
    kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
    ```

  Connect to the Oracle Backend for Spring Boot and Microservices admin service using this command.  Use `obaas-admin` as the username and the password you obtained in the previous step.

    ```shell
    oractl> connect
    username: obaas-admin
    password: **************
    Credentials successfully authenticated! obaas-admin -> welcome to OBaaS CLI.
    oractl:>
    ```

  Run this command to deploy your account service, make sure you provide the correct path to your JAR files.

    ```shell
    oractl:> deploy --app-name application --service-name account --artifact-path /path/to/accounts-0.0.1-SNAPSHOT.jar --image-version 0.0.1 --liquibase-db admin
    uploading: account/target/accounts-0.0.1-SNAPSHOT.jar
    building and pushing image...
    creating deployment and service... successfully deployed
    oractl:>
    ```

   Run this command to deploy the transfer service, make sure you provide the correct path to your JAR files.

    ```shell
    oractl:> deploy --app-name application --service-name transfer --artifact-path /path/to/transfer-0.0.1-SNAPSHOT.jar --image-version 0.0.1
    uploading: transfer/target/transfer-0.0.1-SNAPSHOT.jar
    building and pushing image...
    creating deployment and service... successfully deployed
    oractl:>
    ```

   Your applications are now deployed in the backend.

