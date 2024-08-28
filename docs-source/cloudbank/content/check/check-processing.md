+++
archetype = "page"
title = "Create the Check Processing Microservice"
weight = 6
+++

Next, you will create the "Check Processing" microservice which you will receive messages from the ATM and Back Office and process them by calling the appropriate endpoints on the Account service. This service will also introduce the use of service discovery using [OpenFeign](https://spring.io/projects/spring-cloud-openfeign) clients.

1. Create a new Java Project for the `checks` service.

  In the Explorer of VS Code open `Java Project` and click the **plus** sign to add a Java Project to your workspace.

  ![Add Java Project](../images/add_java_project.png " ")

  Select Spring Boot Project.

  ![Spring Boot Project](../images/spring-boot-prj.png " ")

  Select Maven Project.

  ![Maven Project](../images/maven-project.png " ")

  Specify `3.3.1` as the Spring Boot version.

  ![Spring Boot Version](../images/spring-boot-version.png " ")

  Use `com.example` as the Group Id.

  ![Group Id](../images/group-id.png " ")

  Enter `checks` as the Artifact Id.

  ![Artifact Id](../images/artifact-id-checks.png " ")

  Use `JAR` as the Packaging Type.

  ![Packaging Type](../images/packaging-type.png " ")

  Select Java version `21`.

  ![Java Version](../images/java-version.png " ")

  Search for `Spring Web`, `Lombok`, `Feign` and `Eureka Client`. When all are selected press **Enter**.

  ![Search for Spring Web](../images/checks-dependencies.png " ")

  Press **Enter** to continue and create the Java Project

  ![Create Project](../images/create-project.png " ")

  Select the `root` location for your project e.g. side by side with the `checks`, `testrunner` and `account` projects.

  ![Project Location](../images/project-location.png " ")

  When the project opens click **Add to Workspace**

  ![Add to Workspace](../images/add-to-workspace.png " ")

1. Update the `pom.xml` file for Oracle Spring Boot Starters

  It is very similar to the POM for the account and test runner services, however the dependencies are slightly different.  This service will use the "Web" Spring Boot Starter which will allow it to expose REST endpoints and make REST calls to other services. It also uses the two Oracle Spring Boot Starters for UCP and Wallet to access the database. You will also add the Eureka client and [OpenFeign](https://spring.io/projects/spring-cloud-openfeign) dependencies to allow service discovery and client side load balancing. Open the `pom.xml` and add the following to the `pom.xml`:

    ```xml
    
    <dependency>
      <groupId>com.oracle.database.spring</groupId>
      <artifactId>oracle-spring-boot-starter-aqjms</artifactId>
      <version>23.4.0</version>
    </dependency>
    <dependency>
      <groupId>com.oracle.database.spring</groupId>
      <artifactId>oracle-spring-boot-starter-wallet</artifactId>
      <type>pom</type>
      <version>23.4.0</version>
    </dependency>
    ```

1. Create the Spring Boot application YAML file

  In the `checks` project, rename the file called `application.properties` to `application.yaml` located in the `src/main/resources`. This will be the Spring Boot application configuration file. Add the following content:

    ```yaml
    spring:
      application:
        name: checks

      datasource:
        url: ${spring.datasource.url}
        username: ${spring.datasource.username}
        password: ${spring.datasource.password}

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

  This is the Spring Boot application YAML file, which contains the configuration information for this service.  In this case, you need to provide the application name and the connection details for the database hosting the queues and the information for the Eureka server as the checks application will use a Feign client.

1. Create the main Spring Application class

  In the `checks` directory, create a new directory called `src/main/java/com/example/checks` and in that directory, create a new Java file called `ChecksApplication.java` with this content.  This is a standard Spring Boot main class, notice the `SpringBootApplication` annotation on the class.  It also has the `EnableJms` annotation which tells Spring Boot to enable JMS functionality in this application.  The `main` method is a normal Spring Boot main method:

    ```java
    package com.example.checks;

    import jakarta.jms.ConnectionFactory;

    import org.springframework.boot.SpringApplication;
    import org.springframework.boot.autoconfigure.SpringBootApplication;
    import org.springframework.boot.autoconfigure.jms.DefaultJmsListenerContainerFactoryConfigurer;
    import org.springframework.cloud.openfeign.EnableFeignClients;
    import org.springframework.context.annotation.Bean;
    import org.springframework.jms.annotation.EnableJms;
    import org.springframework.jms.config.DefaultJmsListenerContainerFactory;
    import org.springframework.jms.config.JmsListenerContainerFactory;
    import org.springframework.jms.core.JmsTemplate;
    import org.springframework.jms.support.converter.MappingJackson2MessageConverter;
    import org.springframework.jms.support.converter.MessageConverter;
    import org.springframework.jms.support.converter.MessageType;

    @SpringBootApplication
    @EnableFeignClients
    @EnableJms
    public class ChecksApplication {

        public static void main(String[] args) {
            SpringApplication.run(ChecksApplication.class, args);
        }
    
        @Bean // Serialize message content to json using TextMessage
        public MessageConverter jacksonJmsMessageConverter() {
            MappingJackson2MessageConverter converter = new MappingJackson2MessageConverter();
            converter.setTargetType(MessageType.TEXT);
            converter.setTypeIdPropertyName("_type");
            return converter;
        }

        @Bean 
        public JmsTemplate jmsTemplate(ConnectionFactory connectionFactory) {
            JmsTemplate jmsTemplate = new JmsTemplate();
            jmsTemplate.setConnectionFactory(connectionFactory);
            jmsTemplate.setMessageConverter(jacksonJmsMessageConverter());
            return jmsTemplate;
        }

        @Bean
        public JmsListenerContainerFactory<?> factory(ConnectionFactory connectionFactory,
                                DefaultJmsListenerContainerFactoryConfigurer configurer) {
            DefaultJmsListenerContainerFactory factory = new DefaultJmsListenerContainerFactory();
            // This provides all boot's default to this factory, including the message converter
            configurer.configure(factory, connectionFactory);
            // You could still override some of Boot's default if necessary.
            return factory;
        }

    }
    ```  

  As in the Test Runner service, you will also need the `MessageConverter` and `JmsTemplate` beans.  You will also need an additional bean in this service, the `JmsListenerConnectionFactory`.  This bean will be used to create listeners that receive messages from JMS queues.  Note that the JMS `ConnectionFactory` is injected as in the Test Runner service.

1. Create the model classes

  Create a directory called `src/main/java/com/example/testrunner/model` and in that directory create the two model classes.  

  **Note**: These are in the `testrunner` package, not the `checks` package!  The classes used for serialization and deserialization of the messages need to be the same so that the `MessageConverter` knows what to do.

  First, `CheckDeposit.java` with this content:

    ```java
    package com.example.testrunner.model;

    import lombok.AllArgsConstructor;
    import lombok.Data;
    import lombok.Getter;
    import lombok.NoArgsConstructor;
    import lombok.Setter;
    import lombok.ToString;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    @Getter
    @Setter
    @ToString
    public class CheckDeposit {
        private long accountId;
        private long amount;
    }
    ```

  And then, `Clearance.java` with this content:

    ```java
    package com.example.testrunner.model;

    import lombok.AllArgsConstructor;
    import lombok.Data;
    import lombok.Getter;
    import lombok.NoArgsConstructor;
    import lombok.Setter;
    import lombok.ToString;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    @Getter
    @Setter
    @ToString
    public class Clearance {
        private long journalId;
    }
    ```

1. Create the OpenFeign clients

  > **OpenFeign**
  > In this step you will use OpenFeign to create a client.  OpenFeign allows you to look up an instance of a service from the Spring Eureka Service Registry using its key/identifier, and will create a client for you to call endpoints on that service.  It also provides client-side load balancing.  This allows you to easily create REST clients without needing to know the address of the service or how many instances are running.

  Create a directory called `src/main/java/com/example/checks/clients` and in this directory create a new Java interface called `AccountClient.java` to define the OpenFeign client for the account service. Here is the content:

    ```java
    package com.example.checks.clients;

    import org.springframework.cloud.openfeign.FeignClient;
    import org.springframework.web.bind.annotation.PathVariable;
    import org.springframework.web.bind.annotation.PostMapping;
    import org.springframework.web.bind.annotation.RequestBody;

    @FeignClient("account")
    public interface AccountClient {
        
        @PostMapping("/api/v1/account/journal")
        void journal(@RequestBody Journal journal);

        @PostMapping("/api/v1/account/journal/{journalId}/clear")
        void clear(@PathVariable long journalId);

    }
    ```

  In the interface, you define methods for each of the endpoints you want to be able to call.  As you see, you specify the request type with an annotation, the endpoint path, and you can specify path variables and the body type.  You will need to define the `Journal` class.

  In the same directory, create a Java class called `Journal.java` with the following content:

    ```java
    package com.example.checks.clients;

    import lombok.AllArgsConstructor;
    import lombok.Data;
    import lombok.NoArgsConstructor;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public class Journal {
        private long journalId;
        private String journalType;
        private long accountId;
        private String lraId;
        private String lraState;
        private long journalAmount;

        public Journal(String journalType, long accountId, long journalAmount) {
            this.journalType = journalType;
            this.accountId = accountId;
            this.journalAmount = journalAmount;
            this.lraId = "0";
            this.lraState = "";
        }
    }
    ```

  **Note**:  The `lraId` and `lraState` field are set to reasonable default values, since we are not going to be using those fields in this lab.

1. Create the services

  Next, you will create a service to implement the methods defined in the OpenFeign client interface.  Create a directory called `src/main/java/com/example/checks/service` and in that directory create a Java class called `AccountService.java` with this content.  The services are very simple, you just need to use the `accountClient` to call the appropriate endpoint on the Account service and pass through the data. **Note** the `AccountClient` will be injected by Spring Boot because of the `RequiredArgsConstructor` annotation, which saves some boilerplate constructor code:

    ```java
    package com.example.checks.service;

    import org.springframework.stereotype.Service;

    import com.example.checks.clients.AccountClient;
    import com.example.checks.clients.Journal;
    import com.example.testrunner.model.Clearance;

    import lombok.RequiredArgsConstructor;

    @Service
    @RequiredArgsConstructor
    public class AccountService {
        
        private final AccountClient accountClient;

        public void journal(Journal journal) {
            accountClient.journal(journal);
        }

        public void clear(Clearance clearance) {
            accountClient.clear(clearance.getJournalId());
        }

    }
    ```

1. Create the Check Receiver controller

  This controller will receive messages on the `deposits` JMS queue and process them by calling the `journal` method in the `AccountService` that you just created, which will make a REST POST to the Account service, which in turn will write the journal entry into the accounts' database.

  Create a directory called `src/main/java/com/example/checks/controller` and in that directory, create a new Java class called `CheckReceiver.java` with the following content.  You will need to inject an instance of the `AccountService` (in this example the constructor is provided, so you can compare to the annotation used previously). Implement a method to receive and process the messages. To receive messages from the queues, use the `JmsListener` annotation and provide the queue and factory names. This method should call the `journal` method on the `AccountService` and pass through the necessary data.  Also, notice that you need to add the `Component` annotation to the class so that Spring Boot will load an instance of it into the application:

    ```java
    package com.example.checks.controller;

    import org.springframework.jms.annotation.JmsListener;
    import org.springframework.stereotype.Component;

    import com.example.checks.clients.Journal;
    import com.example.checks.service.AccountService;
    import com.example.testrunner.model.CheckDeposit;

    import lombok.extern.slf4j.Slf4j;

    @Slf4j
    @Component
    public class CheckReceiver {

        private AccountService accountService;

        public CheckReceiver(AccountService accountService) {
            this.accountService = accountService;
        }

        @JmsListener(destination = "deposits", containerFactory = "factory")
        public void receiveMessage(CheckDeposit deposit) {
            log.info("Received deposit <" + deposit + ">");
            accountService.journal(new Journal("PENDING", deposit.getAccountId(), deposit.getAmount()));
        }

    }
    ```

1. Create the Clearance Receiver controller

  In the same directory, create another Java class called `ClearanceReceiver.java` with the following content.  This is very similar to the previous controller, but listens to the `clearances` queue instead, and calls the `clear` method on the `AccountService`:

    ```java
    package com.example.checks.controller;

    import org.springframework.jms.annotation.JmsListener;
    import org.springframework.stereotype.Component;

    import com.example.checks.service.AccountService;
    import com.example.testrunner.model.Clearance;

    import lombok.extern.slf4j.Slf4j;

    @Slf4j
    @Component
    public class ClearanceReceiver {

        private AccountService accountService;

        public ClearanceReceiver(AccountService accountService) {
            this.accountService = accountService;
        }

        @JmsListener(destination = "clearances", containerFactory = "factory")
        public void receiveMessage(Clearance clearance) {
            log.info("Received clearance <" + clearance + ">");
            accountService.clear(clearance);
        }

    }
    ```

   That completes the Check Processing service.  Now you can deploy and test it.

1. Build a JAR file for deployment

  Run the following command to build the JAR file.

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

1. Create a binding for the Check service

  Create a binding so the Check service can access the Oracle Autonomous Database as the `account` user. Run this command to create the binding, and type in the password for the `account` user when prompted. The password is `Welcome1234##`:

    ```shell
    oractl:> bind --app-name application --service-name checks --username account
    ```

1. Deploy the Check service

  You will now deploy your Check service to the Oracle Backend for Spring Boot and Microservices using the CLI. Run this command to deploy your service, make sure you provide the correct path to your JAR file. **Note** that this command may take 1-3 minutes to complete:

    ```shell
    oractl:> deploy --app-name application --service-name checks --artifact-path /path/to/checks-0.0.1-SNAPSHOT.jar --image-version 0.0.1
    uploading: testrunner/target/testrunner-0.0.1-SNAPSHOT.jarbuilding and pushing image...
    creating deployment and service... successfully deployed
    oractl:>
    ```

  You can close the port forwarding session for the CLI now (just type a Ctrl+C in its console window).

1. Testing the service

  Since you had messages already sitting on the queues, the service should process those as soon as it starts.  You can check the service logs to see the log messages indicating this happened using this command:

    ```shell
    $ kubectl -n application logs svc/checks
    ( ... lines omitted ...)
    Received deposit <CheckDeposit(accountId=2, amount=200)>
    Received clearance <Clearance(journalId=4)>
    ( ... lines omitted ...)
    ```

  You can also look at the journal table in the database to see the results.

