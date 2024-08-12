+++
archetype = "page"
title = "Explore Eureka Service Registry"
weight = 5
+++


Spring Eureka Service Registry is an application that holds information about what microservices are running in your environment, how many instances of each are running, and on which addresses and ports.  Spring Boot microservices register with Eureka at startup, and it regularly checks the health of all registered services.  Services can use Eureka to make calls to other services, thereby eliminating the need to hard code service addresses into other services.

1. Start a port-forward tunnel to access the Eureka web user interface

   Start the tunnel using this command.  You can run this in the background if you prefer.

    ```shell
    $ kubectl -n eureka port-forward svc/eureka 8761:8761
    ```

   Open a web browser to [http://localhost:8761](http://localhost:8761) to view the Eureka web user interface.  It will appear similar to the image below.

   ![Eureka web user interface](../images/obaas-eureka.png " ")

   Notice that you can see your own services like the Accounts, Credit Score and Customer services from the CloudBank sample application, as well as platform services like Spring Admin, the Spring Config server and Conductor.

