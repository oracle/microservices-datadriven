
## Validate the application registered with Eureka

Spring Cloud Netflix provides Netflix OSS integrations for Spring Boot apps through autoconfiguration and binding to the Spring Environment and other Spring programming model idioms. The patterns provided include Service Discovery (Netflix Eureka service registry).

Eureka Server is an application that holds the information about all client-service applications. Every microservice will register into the Eureka server and Eureka server knows all the client applications running on each port and IP address.

1. Exposing Eureka Dashboard using `port-forward`

    ```shell
    kubectl port-forward -n apisix svc/apisix-dashboard 8761:8761
    ```

2. Open the Eureka Dashboard URL: <http://localhost:8761>

    <!-- spellchecker-disable -->
    {{< img name="obaas-eureka-dashboard" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    * On the web page, look for an entry called "SLOW" - the presence of this entry confirms that the application successfully registered itself with the service registry
    * You should also see "CONFIG-SERVER" and "ADMIN-SERVER" there
