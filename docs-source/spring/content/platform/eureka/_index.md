---
title: "Service Discovery"
resources:
  - name: obaas-eureka-dashboard
    src: "obaas-eureka-dashboard.png"
    title: "Eureka web user interface"
---

Oracle Backend for Spring Boot and Microservices includes the Spring Boot Eureka service registry, which is an application that stores information about
client services or applications. Typically, each Microservice registers with the Eureka server at startup and the Eureka server maintains
a list of all active instances of the service, including their ports and IP addresses. This information can be accessed by other services
using a well-known key. This allows services to interact with each other without needing to know the other addresses at development or
deployment time.

### Access the Eureka Web User Interface

To access the Eureka web user interface, process these steps:

1. Expose the Eureka web user interface using this command:

    ```shell
    kubectl port-forward -n eureka svc/eureka 8761:8761
    ```

2. Open the Eureka web user interface URL <http://localhost:8761>

    <!-- spellchecker-disable -->
    {{< img name="obaas-eureka-dashboard" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

    * On the web page, you see all of the services registered with Eureka. If you deployed the [sample applications](../../sample-apps),
	  look for an entry called **SLOW**. The presence of this entry confirms that the application successfully registered itself with the
	  service registry.
	  
    * You should also see the **CONFIG-SERVER** and **ADMIN-SERVER** applications. These applications are deployed as part of the platform.

