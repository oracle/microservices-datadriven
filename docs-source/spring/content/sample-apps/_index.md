---
title: Sample Apps
description: "Sample applications that demonstrate Oracle BaaS use case scenarios"
resources:
  - name: oci-container-repository-create
    src: "oci-container-repository-create.png"
    title: "OCI-R : Create Repository to host application image"
    # params:
    #   credits: "[Jay Mantri](https://unsplash.com/@jaymantri) on [Unsplash](https://unsplash.com/s/photos/forest)"
  - name: obaas-sample-apps-build-result
    src: "obaas-sample-apps-build-result.png"
    title: "OBaaS : Sample Application build results"
  - name: obaas-sample-apps-deploy
    src: "obaas-sample-apps-deploy.png"
    title: "OBaaS : All resources from the Sample Application deployed on Kubernetes"

weight: 12
draft: false
---

Sample applications that demonstrate Oracle BaaS use case scenarios

## Prerequisites

* GraalVM or OpenJDK 17
* Apache Maven 3.8+
* A Docker Cli (to use for login against OCI-R)

## Make a Clone of the Sample Apps Source Code

Now that you have your OBaaS environment available and accessible, we can start deploying the Sample applications.

1. To work with the application code, you need to make a clone from the OraHub repository using the following command.  

 ```shell
 git clone https://xxxxx
 ```

You should now see the directory `ebaas-sample-apps` in the directory that you created.

## Create OCI Repositories to Sample Applications

1. You have to create the repositories for each sample application in your compartment. The name of the repository should follow the pattern `<project name>/<app name>`

    <!-- spellchecker-disable -->
    {{< img name="oci-container-repository-create" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    The repositories are:

    * `<project>/banka`
    * `<project>/bankb`
    * `<project>/customer`
    * `<project>/fraud`
    * `<project>/notification`
    * `<project>/slow_service`

2. Create the auth-token to login to OCI-R using kubectl following the instructions on [Generating an Auth Token to Enable Login to Oracle Cloud Infrastructure Registry](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsgenerateauthtokens.htm)

3. Now you can login to OCI-R to allow you push the Sample Applications container images, executing the following commnad:

    ```shell
    docker login <region>.ocir.io
    username: <tenancy>/oracleidentitycloudservice/<username>
    password: <auth-token>
    ```

## Build Sample Applications and push container images

1. Update the `pom.xml` in the root directory to set your Container Registry. Configure region/tenancy and the right project name:

    ```xml
        <properties>
            <container.registry>region ocir address/tenancy name/project name</container.registry>
        </properties>
    ```

    For example, if your region is Phoenix and prject name is `myproject`

    ```xml
        <properties>
            <container.registry>phx.ocir.io/mytenancy/myproject</container.registry>
        </properties>
    ```

2. Run package using Maven with this profile:

    ```shell
    mvn package -P build-docker-image
    ```

    Finishing the build and push process, you will be able to see a message similar to the one below portraying that all modules were builded successfully.

    <!-- spellchecker-disable -->
    {{< img name="obaas-sample-apps-build-result" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## Update Images in Kubernetes Deployment Descriptors

You also have to update the address of images in application deployment descriptor editing each `01--deployment--APPLICATION_NAME.yaml`.

```yaml
    spec:
      containers:
      - name: app_name
        image: phx.ocir.io/mytenancy/myproject/app_image:latest
```

## Create Datbase Objects for each appliaction

Connected to the ADB instance using aforementioned instructions execute the sql commands for each application to create application database. You have to edit sql script to add user database password.

1. Customer microservice

    * db-01-customer-create-user.sql

2. Fraud microservice

    * db-01-fraud-create-user.sql

3. Notification microservice

    * db-01-notification-create-user.sql
    * db-03-notifications-db-queue.sql

## Add appliactions configurations into Config Server Properties Table

Connected to the ADB instance using aforementioned instructions execute the sql commands for each application but before we have to adjust configurations for the applications inside `db-02-<application>-configserver-props.sql` file.

```sql
INSERT INTO CONFIGSERVER.PROPERTIES(APPLICATION, PROFILE, LABEL, PROP_KEY, "VALUE")
VALUES ('APPLICATION_NAME', 'kube', 'latest', 'spring.datasource.url', 'jdbc:oracle:thin:@TNS_NAME?TNS_ADMIN=/oracle/tnsadmin');

INSERT INTO CONFIGSERVER.PROPERTIES (APPLICATION, PROFILE, LABEL, PROP_KEY, VALUE)
VALUES ('APPLICATION_NAME', 'kube', 'latest', 'spring.datasource.driver-class-name', 'oracle.jdbc.OracleDriver');

COMMIT;
```

1. Customer microservice

    * db-02-customer-configserver-props.sql

2. Fraud microservice

    * db-02-fraud-configserver-props.sql

3. Notification microservice

    * db-02-notification-configserver-props.sql

## Add Kubernetes Secret for each Application database credential

For each application, you will have a user created and its pasword, you have to inform to the application these credential. In this current version of BaaS, you have to create a Kubernetes Secret to hold this credentials for each application. You make this executing the following commands:

1. Customer microservice

    ```cmd
     k -n application create secret generic oracledb-creds-customer --from-literal=sping.db.username=CUSTOMER --from-literal=spring.db.password=[DB_PASSWORD]
    ```

2. Fraud microservice

    ```cmd
     k -n application create secret generic oracledb-creds-fraud --from-literal=sping.db.username=FRAUD --from-literal=spring.db.password=[DB_PASSWORD]
    ```

3. Notification microservice

    ```cmd
     k -n application create secret generic oracledb-creds-notification --from-literal=sping.db.username=NOTIFICATIONS --from-literal=spring.db.password=[DB_PASSWORD]
    ```

## Deploy the applicatios

1. Apply Application deployment using kubectl

    ```shell
    cd <app dir>
    kubectl apply -f 01--deployment--<app name>.yaml
    ```

2. Deploy Application Service using kubectl

    ```shell
    kubectl apply -f 02--service--<app name>.yaml
    ```

3. Deploy Application Ingress using kubectl

    ```shell
    kubectl apply -f 03--ingress--<app name>.yaml
    ```

    After deploy all microservices, you will be able to check them executing on Kubernetes executing the following command:

    ```shell
    kubectl --namespace=application get all -o wide
    ```

    <!-- spellchecker-disable -->
    {{< img name="obaas-sample-apps-deploy" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

## Explore the applications

### Amigos Microservices APIs

1. Create customer

    ```shell
    curl -X POST -H 'Content-Type: application/json' -d '{"firstName": "bob", "lastName": "smith", "email": "bob@bob.com"}' http://<ExternalIP>/customer/api/v1/customers
    ```

2. Send notification

    ```shell
    curl -X POST -H 'Content-Type: application/json' -d '{"toCustomerId": 1, "toCustomerEmail": "bob@bob.com", "message": "hi bob"}' http://<ExternalIP>/notification/api/v1/notify
    ```

3. Fraud check

    ```shell
    curl -X GET http://<ExternalIP>/fraud/api/v1/fraud-check/1
    ```

### CloudBank APIs

1. Transfer

    ```shell
    curl  -X POST -H 'Content-Type: application/json' -d '{"fromAccount": "1", "toAccount": "2", "amount": 500}'   http://<ExternalIP>/banka/transfer
    ````
