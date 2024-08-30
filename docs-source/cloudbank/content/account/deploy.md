+++
archetype = "page"
title = "Deploy Account Service"
weight = 9
+++


1. Prepare the data source configuration for deployment

    Update the data source configuration in your `src/main/resources/application.yaml` as shown in the example below.  This will cause the service to read the correct database details that will be injected into its pod by the Oracle Backend for Spring Boot and Microservices.

    ```yaml
    datasource:
      url: ${spring.datasource.url}
      username: ${spring.datasource.username}
      password: ${spring.datasource.password}
    ```

1. Add the client and configuration for the Spring Eureka Service Registry

    When you deploy the application to the backend, you want it to register with the Eureka Service Registry so that it can be discovered by other services including the APISIX API Gateway, so that we can easily expose it outside the cluster.

    Add the following line to the `<properties>` to the Maven POM file:

    ```xml
    
    <spring-cloud.version>2023.0.0</spring-cloud.version>
    
    ```

    Add the dependency for the client to the Maven POM file:

    ```xml
    
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
    
    ```

    Add the dependency management to the Maven POM file:

    ```xml
    
    <dependencyManagement>
      <dependencies>
          <dependency>
              <groupId>org.springframework.cloud</groupId>
              <artifactId>spring-cloud-dependencies</artifactId>
              <version>${spring-cloud.version}</version>
              <type>pom</type>
              <scope>import</scope>
          </dependency>
      </dependencies>
    </dependencyManagement>
    
    ```

    Add the `@EnableDiscoveryClient` annotation to the `AccountsApplication` class to enable the service registry.

    ```java
    
    import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

    // .. 

    @SpringBootApplication
    @EnableDiscoveryClient
    public class AccountsApplication {       
    
    ```

    Add the configuration to `src/main/resources/application.yaml` file.

    ```yaml
    
    eureka:
      instance:
        hostname: ${spring.application.name}
        preferIpAddress: true
      client:
        service-url:
          defaultZone: ${eureka.service-url}
        fetch-registry: true
        register-with-eureka: true
        enabled: true
    
    ```

1. Build a JAR file for deployment

    Run the following command to build the JAR file (it will also remove any earlier builds).  Note that you will need to skip tests now, since you updated the `application.yaml` and it no longer points to your local test database instance.

    ```shell
    $ mvn clean package -DskipTests
    ```

    The service is now ready to deploy to the backend.

1. Prepare the backend for deployment

    The Oracle Backend for Spring Boot and Microservices admin service is not exposed outside the Kubernetes cluster by default. Oracle recommends using a **kubectl** port forwarding tunnel to establish a secure connection to the admin service.

    Start a tunnel using this command in a new terminal window:

    ```shell
    $ kubectl -n obaas-admin port-forward svc/obaas-admin 8080
    ```

    Get the password for the `obaas-admin` user. The `obaas-admin` user is the equivalent of the admin or root user in the Oracle Backend for Spring Boot and Microservices backend.

    ```shell
    $ kubectl get secret -n azn-server  oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
    ```

    Start the Oracle Backend for Spring Boot and Microservices CLI (*oractl*) in a new terminal window using this command:

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

    Connect to the Oracle Backend for Spring Boot and Microservices admin service using the `connect` command. Enter `obaas-admin` and the username and use the password you collected earlier.

    ```shell
    oractl> connect
    username: obaas-admin
    password: **************
    Credentials successfully authenticated! obaas-admin -> welcome to OBaaS CLI.
    oractl:>
    ```

    Create a database "binding" by tunning this command.  Enter the password (`Welcome1234##`) when prompted.  This will create a Kubernetes secret in the `application` namespace called `account-db-secrets` which contains the username (`account`), password, and URL to connect to the Oracle Autonomous Database instance associated with the Oracle Backend for Spring Boot and Microservices.

    ```shell
    oractl:> bind --app-name application --service-name account
    Database/Service Password: *************
    Schema {account} was successfully Not_Modified and Kubernetes Secret {application/account} was successfully Created.
    oractl:>
    ```

    This created a Kubernetes secret with the credentials to access the database using this Spring Boot microservice application's username and password.  When you deploy the application, its pods will have the keys in this secret injected as environment variables so the application can use them to authenticate to the database.

1. Deploy the account service

    You will now deploy your account service to the Oracle Backend for Spring Boot and Microservices using the CLI.  You will deploy into the `application` namespace, and the service name will be `account`.  Run this command to deploy your service, make sure you provide the correct path to your JAR file.  **Note** that this command may take 1-3 minutes to complete:

    ```shell
    oractl:> deploy --app-name application --service-name account --artifact-path /path/to/accounts-0.0.1-SNAPSHOT.jar --image-version 0.0.1
    uploading: /Users/atael/tmp/cloudbank/accounts/target/accounts-0.0.1-SNAPSHOT.jar
    building and pushing image...

    creating deployment and service...
    obaas-cli [deploy]: Application was successfully deployed
    NOTICE: service not accessible outside K8S
    oractl:>
    ```

    > What happens when you use the Oracle Backend for Spring Boot and Microservices CLI (*oractl*) **deploy** command? When you run the **deploy** command, the Oracle Backend for Spring Boot and Microservices CLI does several things for you:

    * Uploads the JAR file to server side
    * Builds a container image and push it to the OCI Registry
    * Inspects the JAR file and looks for bind resources (JMS)
    * Create the microservices deployment descriptor (k8s) with the resources supplied
    * Applies the k8s deployment and create k8s object service to microservice

1. Verify account service

    You can check if the account service is running properly by running the following command:

    ```shell
    $ kubectl logs -n application svc/account
    ```
  
    The command will return the logfile content for the account service. If everything is running properly you should see something like this:

    ```text
    2023-06-01 20:44:24.882  INFO 1 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
    2023-06-01 20:44:24.883  INFO 1 --- [           main] .s.c.n.e.s.EurekaAutoServiceRegistration : Updating port to 8080
    2023-06-01 20:44:24.903  INFO 1 --- [           main] c.example.accounts.AccountsApplication   : Started AccountsApplication in 14.6 seconds (JVM running for 15.713)
    2023-06-01 20:44:31.971  INFO 1 --- [nio-8080-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
    2023-06-01 20:44:31.971  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
    2023-06-01 20:44:31.975  INFO 1 --- [nio-8080-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 4 ms
    ```

1. Check the Eureka Server

    Create a tunnel to the Eureka server, so you can verify the `ACCOUNTS` application has registered with the server.

    ```shell
    $ kubectl -n eureka port-forward svc/eureka 8761
    ```
  
    Open a web browser to [Eureka Dashboard](http://localhost:8761) to vew the Eureka Server dashboard web user interface. It will look similar to this. Note that the `ACCOUNT` application you have built has registered with Eureka.

  ![Eureka Server Web Interface](../images/eureka-dashboard.png " ")

## Task 8: Expose the account service using the APISIX API Gateway

Now that the account service is deployed, you need to expose it through the API Gateway so that clients will be able to access it.  This is done by creating a "route" in APISIX Dashboard.

1. Retrieve the admin password for the APISIX API Gateway.

    Execute the following command to get the password for the `admin` user for the APISIX API Gateway:

    ```shell
    $ kubectl get secret -n apisix apisix-dashboard -o jsonpath='{.data.conf\.yaml}' | base64 -d | grep 'password:'
    ```

1. Access the APISIX Dashboard

    The APISIX Dashboard isn't exposed outside the cluster. You need to start a tunnel to be able to access APISIX Dashboard. Start the tunnel using this command in a new terminal window:

    ```shell
    $ kubectl -n apisix port-forward svc/apisix-dashboard 8090:80
    ```

    Open a web browser to [APISIX Dashboard](http://localhost:8090) to view the APISIX Dashboard web user interface.  It will appear similar to the image below.

    If prompted to login, login with username `admin` and the password you retrieved earlier. Note that Oracle strongly recommends that you change the password, even though this interface is not accessible outside the cluster without a tunnel.

    Open the **routes** page from the left hand side menu.  You will not have any routes yet.

   ![APISIX Dashboard route list](../images/obaas-apisix-route-list.png " ")

1. Create the route

    Click on the **Create** button to start creating a route.  The **Create route** page will appear. Enter `account` in the **Name** field:

    ![APISIX Create route](../images/obaas-apisix-create-route-1.png " ")

    Scroll down to the **Request Basic Define** section.  Set the **Path** to `/api/v1/account*`.  This tells APISIX API Gateway that any incoming request for that URL path (on any host or just IP address) should use this route.  In the **HTTP Method** select `GET`, `POST`, `DELETE`, and `OPTIONS`.  The first three you will recall using directly in the implementation of the account service during this lab.  User interfaces and other clients will often send an `OPTIONS` request before a "real" request to see if the service exists and check headers and so on, so it is a good practice to allow `OPTIONS` as well.

    ![APISIX Create route](../images/obaas-apisix-create-route-2.png " ")

    Click on the **Next** button to move to the **Define API Backend Server** page.  On this page you configure where to route requests to. In the **Upstream Type** field, select **Service Discovery**.  Then in the **Discovery Type** field, select **Eureka**.  In the **Service Name** field enter `ACCOUNT`.  This tells APISIX to lookup the service in Spring Eureka Service Registry with the key `ACCOUNT` and route requests to that service using a Round Robin algorithm to distribute requests.

    ![APISIX Create route](../images/obaas-apisix-create-route-3.png " ")

    Click on **Next** to go to the **Plugin Config** page.  You will not add any plugins right now.  You may wish to browse through the list of available plugins on this page.  When you are ready, click on **Next** to go to the **Preview** page.  Check the details and then click on **Submit** to create the route.

    When you return to the route list page, you will see your new `account` route in the list now.

   ![APISIX Route Created](../images/obaas-apisix-route-created.png " ")

1. Verify the account service

    In the next two commands, you need to provide the correct IP address for the API Gateway in your backend environment.  You can find the IP address using this command, you need the one listed in the **`EXTERNAL-IP`** column:

    ```shell
    $ kubectl -n ingress-nginx get service ingress-nginx-controller
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.123.10.127   100.20.30.40  80:30389/TCP,443:30458/TCP   13d
    ```

    Test the create account endpoint with this command, use the IP address (**EXTERNAL-IP** in the table above) for your API Gateway:

    ```shell
    $ curl -i -X POST \
      -H 'Content-Type: application/json' \
      -d '{"accountName": "Sanjay''s Savings", "accountType": "SA", "accountCustomerId": "bkzLp8cozi", "accountOtherDetails": "Savings Account"}' \
      http://<EXTERNAL-IP>/api/v1/account
    HTTP/1.1 201
    Date: Wed, 01 Mar 2023 18:35:31 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"accountId":24,"accountName":"Sanjays Savings","accountType":"SA","accountCustomerId":"bkzLp8cozi","accountOpenedDate":null,"accountOtherDetails":"Savings Account","accountBalance":0}
    ```

    Test the get account endpoint with this command, use the IP address for your API Gateway and the `accountId` that was returned in the previous command:

    ```shell
    $ curl -s http://<EXTERNAL-IP>/api/v1/account/24 | jq .
    {
      "accountId": 24,
      "accountName": "Sanjay's Savings",
      "accountType": "SA",
      "accountCustomerId": "bkzLp8cozi",
      "accountOpenedDate": null,
      "accountOtherDetails": "Savings Account",
      "accountBalance": 1040
    }
    ```

    Your service is deployed in the Oracle Backend for Spring Boot and Microservices environment and using the Oracle Autonomous Database instance associated with the backend.

## Learn More

* [Oracle Backend for Spring Boot and Microservices](https://bit.ly/oraclespringboot)
* [Kubernetes](https://kubernetes.io/docs/home/)
* [Apache APISIX](https://apisix.apache.org)
* [Oracle Cloud Infrastructure](https://docs.oracle.com/en-us/iaas/Content/home.htm)

## Acknowledgements

* **Author** - Andy Tael, Mark Nelson, Developer Evangelists, Oracle Database
* **Contributors** - [](var:contributors)
* **Last Updated By/Date** - Andy Tael, July 2024