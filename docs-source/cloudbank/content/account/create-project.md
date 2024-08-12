+++
archetype = "page"
title = "Create Project"
weight = 2
+++

Create a project to hold your Account service.  In this lab, you will use the Spring Initialzr directly from Visual Studio Code, however it is also possible to use [Spring Initialzr](http://start.spring.io) online and download a zip file with the generated project.

1. Create the project

   In Visual Studio Code, press Ctrl+Shift+P (Cmd+Shift+P on a Mac) to access the command window. Start typing "Spring Init" and you will see a number of options to create a Spring project, as shown in the image below.  Select the option to **Create a Maven Project**.

  ![Start Spring Initializr](../images/obaas-spring-init-1.png " ")

1. Select the Spring Boot Version

   You will be presented with a list of available Spring Boot versions. Choose **3.2.2** (or the latest 3.2.x version available).

  ![Specify Spring Boot version](../images/obaas-spring-init-2.png " ")

1. Choose Group ID.

   You will be asked for the Maven Group ID for this new project, you can use **com.example** (the default value).

  ![Group ID](../images/obaas-spring-init-4.png " ")

1. Choose Artifact ID.

   You will be asked for the Maven Artifact ID for this new project, enter **account**.

  ![Artifact ID](../images/obaas-spring-init-5.png " ")

1. Select Packaging Type

   You will be asked what type of packaging you want for this new project, select **JAR** from the list of options.

  ![Specify packaging type](../images/obaas-spring-init-6.png " ")

1. Choose Java Version

   Next, you will be asked what version of Java to use. Select **21** from the list of options.

   ![Specify Java version](../images/obaas-spring-init-7.png " ")

1. Add Spring Boot dependencies

   Now you will have the opportunity to add the Spring Boot dependencies your project needs. For now just add **Spring Web**, which will let us write some REST services.  We will add more later as we need them.  After you add Spring Web, click on the option to continue with the selected dependencies.

  ![Choose dependencies](../images/obaas-spring-init-8.png " ")

1. Continue with the selected dependencies

  After you add Spring Web, click on the option to continue with the selected dependencies.

  ![Create Project](../images/obaas-spring-init-12.png " ")

1. Select where to save the project

   You will be asked where to save the project. Note that this needs to be an existing location. You may wish to create a directory in another terminal if you do not have a suitable location. Enter the directory to save the project in and press **Enter**.

  ![Project directory](../images/obaas-spring-init-9.png " ")

1. Open the generated project

   Now the Spring Initializr will create a new project based on your selections and place it in the directory you specified. This will only take a few moments to complete. You will a message in the bottom right corner of Visual Studio Code telling you it is complete. Click on the **Open** button in that message to open your new project in Visual Studio Code.

  ![Project generated](../images/obaas-spring-init-10.png " ")

1. When asked if you want to Enable null Analysis for this project press **Enable**.

  ![Enable](../images/obaas-spring-init-13.png " ")

1. Explore the project

   Explore the new project. You should find the main Spring Boot application class and your Spring Boot `application.properties` file as shown in the image below.

   ![Ihe new project](../images/obaas-spring-init-11.png " ")

1. Remove some files (Optional)

   If desired, you can delete some of the generated files that you will not need. You can remove `.mvn`, `mvnw`, `mvnw.cmd` and `HELP.md` if you wish. Leaving them there will not cause any issues.

1. Build and run the service

    Open a terminal in Visual Studio Code by selecting **New Terminal** from the **Terminal** menu (or if you prefer, just use a separate terminal application). Build and run the newly created service with this command:

    ```shell
    $ mvn spring-boot:run
    ```

    The service will take a few seconds to start, and then you will see some messages similar to these:

    ```text
    2024-02-14T14:39:52.501-06:00  INFO 83614 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path ''
    2024-02-14T14:39:52.506-06:00  INFO 83614 --- [           main] com.example.account.AccountApplication   : Started AccountApplication in 0.696 seconds (process running for 0.833)
    ```

    Of course, the service does not do anything yet, but you can still make a request and confirm you get a response from it. Open a new terminal and execute the following command:

    ```shell
    $ curl http://localhost:8080
    {"timestamp":"2023-02-25T17:28:23.264+00:00","status":404,"error":"Not Found","path":"/"}
    ```
