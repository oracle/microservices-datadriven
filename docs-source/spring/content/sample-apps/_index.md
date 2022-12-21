---
title: Sample Apps
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

---

Sample applications that demonstrate Oracle Backend as a Service for Spring Cloud use cases.

## Prerequisites

* GraalVM or OpenJDK 17  (OpenJDK Runtime Environment GraalVM CE 22.3.0 (build 17.0.5+8-jvmci-22.3-b08) recommended)
* Apache Maven 3.8+
* A Docker CLI (to login and push images to OCI Registry)

## Make a Clone of the Sample Apps Source Code

Now that you have your Oracle Backend as a Service for Spring Cloud environment available and accessible, we can start deploying the Sample applications.

1. To work with the application code, you need to make a clone from the OraHub repository using the following command.  

 ```shell
 git clone https://github.com/oracle/microservices-datadriven.git
 cd mbaas-developer-preview/sample-spring-apps/
 ```

This directory contains the sample applications source code.


## Create OCI Repositories for Sample Applications

1. Before building the sample applications, you have to create the repositories for each sample application in your compartment. The name of the repository should follow the pattern `<project name>/<app name>`

    **Note:** If you do not pre-create the repositories, they will be created in the root compartment on the first push.

    <!-- spellchecker-disable -->
    {{< img name="oci-container-repository-create" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    The required repositories are:

    * `<project>/banka`
    * `<project>/bankb`
    * `<project>/customer`
    * `<project>/fraud`
    * `<project>/notification`
    * `<project>/slow_service`

2. Create an Authentication Token to login to OCI Registry by following the instructions on [Generating an Auth Token to Enable Login to Oracle Cloud Infrastructure Registry](https://docs.oracle.com/en-us/iaas/Content/Functions/Tasks/functionsgenerateauthtokens.htm)

3. Login to OCI Registry by executing the following command.  This will allow the build to push the sample applications' container images to OCI Registry.

    ```shell
    docker login <region>.ocir.io
    username: <tenancy>/oracleidentitycloudservice/<username>
    password: <auth-token>
    ```

    **Note:** Your username may not contain `oracleidentitycloudservice` if it is not a federated account, but the tenancy prefix will always be required.

## Build the sample applications and push container images

1. Update the `pom.xml` in the root directory to match the OCI Registry repository prefix you used above. Configure the region, tenancy and project name:

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

    When this completes the build and push process, you will see a message similar to the one below reporting that all modules were builded successfully.

    <!-- spellchecker-disable -->
    {{< img name="obaas-sample-apps-build-result" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## Update Images in Kubernetes Deployment Descriptors

You also have to update the address of images in application deployment descriptor to match the repositories you created.
You can do this by editing the `01--deployment--APPLICATION_NAME.yaml` file in each of the service sub-directories.  Use the
same values you used in the previous steps.

```yaml
    spec:
      containers:
      - name: app_name
        image: phx.ocir.io/mytenancy/myproject/app_image:latest
```

## Create Database Objects for each application

You must create the database users and some objects that are required by the sample services. 
Connect to the Oracle Autonmous Database instance using (using [these instructions](../database)) and execute the SQL statements
for each application. You must edit each SQL script to add your desired password before running the statements.

Each of the following files must be reviewed, updated, and then executed against the database (as the `ADMIN` user). 

1. Customer microservice

    * db-01-customer-create-user.sql

2. Fraud microservice

    * db-01-fraud-create-user.sql

3. Notification microservice

    * db-01-notification-create-user.sql
    * db-03-notifications-db-queue.sql

## Add applications configurations into Config Server Properties Table

You must create the application configuration entries that are required by the sample services. 
Connect to the Oracle Autonmous Database instance using (using [these instructions](../database)) and execute the SQL statements
for each application. You must edit each SQL script to match your environment before running the statements.
The example below shows the lines that must be updated. You must replace the `TNS_NAME` with the correct name
for your database.  If your database is called `OBAASDB` then the `TNS_NAME` is `OBAASDB_TP`.

```sql
INSERT INTO CONFIGSERVER.PROPERTIES(APPLICATION, PROFILE, LABEL, PROP_KEY, "VALUE")
VALUES (
    'APPLICATION_NAME', 
    'kube', 
    'latest', 
    'spring.datasource.url', 
    'jdbc:oracle:thin:@TNS_NAME?TNS_ADMIN=/oracle/tnsadmin'
);
```

Each of the following files must be reviewed, updated, and then executed against the database (as the `ADMIN` user). 

1. Customer microservice

    * db-02-customer-configserver-props.sql

2. Fraud microservice

    * db-02-fraud-configserver-props.sql

3. Notification microservice

    * db-02-notification-configserver-props.sql

## Add Kubernetes Secrets for each application's database credentials

For each application, you need to create a Kuberentes secret containing the database username and password that you chose in the previous steps.
You can create these secrets by executing the following commands (update the values to match your environment):

1. Customer microservice

    ```cmd
     kubectl -n application \
       create secret generic oracledb-creds-customer \
       --from-literal=sping.db.username=CUSTOMER \
       --from-literal=spring.db.password=[DB_PASSWORD]
    ```

2. Fraud microservice

    ```cmd
     kubectl -n application \
       create secret generic oracledb-creds-fraud \
       --from-literal=sping.db.username=FRAUD \
       --from-literal=spring.db.password=[DB_PASSWORD]
    ```

3. Notification microservice

    ```cmd
     kubectl -n application \
       create secret generic oracledb-creds-notification \
       --from-literal=sping.db.username=NOTIFICATIONS \
       --from-literal=spring.db.password=[DB_PASSWORD]
    ```

## Deploy the applications

1. Apply each application's Kubernetes Deployment YAML using `kubectl`:

    ```shell
    cd <app dir>
    kubectl apply -f 01--deployment--<app name>.yaml
    ```

2. Deploy each application's Kuberenetes Service YAML using `kubectl`:

    ```shell
    kubectl apply -f 02--service--<app name>.yaml
    ```


After deploy all microservices, you will be able to check them executing on Kubernetes executing the following command:

```shell
kubectl --namespace=application get all -o wide
```

<!-- spellchecker-disable -->
{{< img name="obaas-sample-apps-deploy" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

## Explore the applications

Before using the application, you need to expose them by creating a route in APISIX API Gateway.

To expose the customer service, see the documentation on [how to create a route](../platform/apigw/#exposing-a-spring-application-through-the-api-gateway-and-load-balancer)
and use these values: 

* name = customer
* path = /api/v1/customers*
* method = get, post, options
* upstream type = service discovery
* discovery type = eureka
* service name = CUSTOMER    (note that this is case sensitive, this is the key from the Eureka dashboard)

Once the route is created, you can access the service using the load balancer IP address (as described on that page) using a call
like this, for example, to create a customer:

```shell
curl -X POST \
     -H 'Content-Type: application/json' \
     -d '{"firstName": "bob", "lastName": "smith", "email": "bob@bob.com"}' \
     http://1.2.3.4>/customer/api/v1/customers
```

After you call the service a few times, you might also like to explore the various platform services, including:

* [Spring Admin Dashboard](../platform/spring-admin) where you can see details of the service including metrics, configuration,
  what endpoints it exposes, what Spring beans are used, etc.
* [Spring Eureka Service Registry](../platform/eureka) where you can see which services are registered and discoverable
* [Prometheus and Grafana](../observability/metrics) which allow you to view metrics and dashboards about the service performance
* [Jaeger](../observability/tracing) which will let you view traces of service executions.  For the cusomter service, look for a
  trace of the POST to `/api/v1/customers` above.  It will show interaction between the customer, fraud and notification services
  and each one writing to its own data store.  The notification service also enqueues a message.