---
title: "API Gateway"
resources:
  - name: obaas-apisix-k8s
    src: "obaas-apisix-k8s.png"
    title: "APISIX K8s"
  - name: obaas-apisix-login
    src: "obaas-apisix-login.png"
    title: "APISIX Login"
  - name: obaas-apisix-routes
    src: "obaas-apisix-routes.png"
    title: "APISIX Routes"
  - name: obaas-apisix-routes-step1
    src: "obaas-apisix-routes-step1.png"
    title: "APISIX Routes Step1"
  - name: obaas-apisix-routes-step2
    src: "obaas-apisix-routes-step2.png"
    title: "APISIX Routes Step2"
  - name: obaas-apisix-routes-step3
    src: "obaas-apisix-routes-step3.png"
    title: "APISIX Routes Step3"
  - name: obaas-apisix-routes-step4
    src: "obaas-apisix-routes-step4.png"
    title: "APISIX Routes Step4"
  - name: obaas-apisix-routes-step5
    src: "obaas-apisix-routes-step5.png"
    title: "APISIX Routes Step5"
---

[Apache APISIX](https://apisix.apache.org) is an open source cloud native API platform that supports the full lifecycle of API management
including publishing, traffic management, deployment strategies, and circuit breakers.

## Deploy and Secure Sample Application APIs using Apache APISIX

Oracle Backend for Spring Boot and Microservices deploys Apache APISIX Gateway and Dashboard in the `apisix` namespace. The gateway is exposed through the
external load balancer and ingress controller. To access the Apache APISIX Dashboard, you must use the `kubectl port-forward` command to
create a secure channel to `service/apisix-dashboard`. Process the following steps:

1. To expose the Apache APISIX Dashboard using this command:

    ```shell
    kubectl port-forward -n apisix svc/apisix-dashboard 8080:80
    ```

2. Open the Apache APISIX Dashboard URL: <http://localhost:8080>

    * username: `admin`
    * password: `admin`

    **NOTE:** Oracle recommends that you change the default password when you log in the first time. Even though the dashboard is not
	accessible externally, Oracle still recommends using strong passwords to maximize security.

    <!-- spellchecker-disable -->
    {{< img name="obaas-apisix-login" size="tiny" lazy=false >}}
    <!-- spellchecker-enable -->

## Exposing a Spring Application Through the API Gateway and Load Balancer

Once you have your application deployed and running, you may want to expose it to the outside world. Some applications may not need to be
exposed if they are only called by other applications in the platform. To expose your application, create a "route" in the Apache APISIX
API Gateway by processing these steps:

1. Create a route to the service. For example:

    a. In the Apache APISIX Dashboard, click **Routes** in the menu on the left side.

      <!-- spellchecker-disable -->
      {{< img name="obaas-apisix-routes" size="medium" lazy=false >}}
      <!-- spellchecker-enable -->

    b. Click **Create** to create a new route.
    
	c. Fill out the necessary details (anything not mentioned here can be left at the default value). For example, for the "slow service"
       to be included in the [Sample Applications](../../sample-apps), provide these details:
	   
      * name = slow
      * path = /fruit*
      * method = get, options
      * upstream type = service discovery
      * discovery type = eureka
      * service name = SLOW (note that this is case sensitive, this is the key from the Eureka dashboard)

        **NOTE:** The API Gateway is pre-configured with both "Eureka" and "Kubernetes" discovery types. For Eureka, the service name is the key used to
		          deploy the service in Eureka, which is normally the value from `spring.application.name` in the Spring Boot configuration
				  file (`src/main/resources/application.yaml`), in uppercase characters. For Kubernetes, the service name is in the
				  format `namespace/service:port` where `namespace` is the Kubernetes namespace in which the Spring Boot application is deployed, `service` is
				  the name of the Kubernetes service for that application, and `port` is the name of the port in that service. If you deployed your Spring Boot
				  application with the Oracle Backend for Spring Boot and Microservices CLI, the port name will be `spring`. For example, an application called `slow-service` deployed
				  in the `my-apps` namespace would be `my-apps/slow-service:spring`.

        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes-step1" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
        </br>
        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes-step2" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
        </br>
        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes-step3" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
        </br>
    
    d. Save the route that you created.
        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes-step4" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
        </br>
        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes-step5" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
        </br>

2. Test a route to the service. For example:

    a. Get the Apache APISIX Gateway external IP using this command:

      ```shell
      kubectl -n ingress-nginx get svc ingress-nginx-controller
      ```

    b. Call the API using the Apache APISIX Gateway address plus path. For example:

      ```shell
      curl http://APISIX_IP/fruit
      ```

      You should get "banana" or "fallback fruit is apple" back as the response.


