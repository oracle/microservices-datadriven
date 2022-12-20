---
title: "Service Discovery"
resources:
  - name: obaas-eureka-dashboard
    src: "obaas-eureka-dashboard.png"
    title: "Eureka web user interface"
---


Oracle Backend as a Service for Spring Cloud includes the Spring Eureka Service Registry, which is an application that stores information about client services/applications. Typically, each microservice will register with the Eureka server at startup and the Eureka server will maintain a list of all active instances of the service, including their ports and IP addresses.  This information can be looked up by other services using a well-known key.  This allows services to interact with each other without needing to know each others addresses at development/deployment time.

### Access the Eureka web user interface

1. Expose the Eureka web user interface using `port-forward`

    ```shell
    kubectl port-forward -n eureka svc/eureka 8080:8080
    ```

2. Open the Eureka web user interface: <http://localhost:8080>

    <!-- spellchecker-disable -->
    {{< img name="obaas-eureka-dashboard" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    * On the web page, you will see all of the services registered with Eureka.  If you deployed the [sample apps](../../sample-apps), look for an entry called "SLOW" - the presence of this entry confirms that the application successfully registered itself with the service registry
    * You should also see "CONFIG-SERVER" and "ADMIN-SERVER" there - these are deployed as part of the platform
