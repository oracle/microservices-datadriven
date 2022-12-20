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

[Apache APISIX](https://apisix.apache.org) is an open source cloud native API platform that support the full lifecycle of API management as publishing, traffic management, deployment strategies, circuit breaking, and so on.

## Deploy and Secure Sample Apps APIs using APISIX

Oracle Backend as a Service for Spring Cloud deploys APISIX inside `apisix` namespace as detailed bellow and to you have access to APISIX Dashboard for this version of OBaaS you have to request a port-foward from the `service/apisix-dashboard`.

```shell
kubectl --namespace apisix get all
```

<!-- spellchecker-disable -->
{{< img name="obaas-apisix-k8s" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

1. Exposing APISIX Dashboard using `port-forward`

    ```shell
    kubectl port-forward -n apisix svc/apisix-dashboard 8080:80
    ```

2. Open the APISIX Dashboard URL: <http://localhost:8080>

    * username: `admin`
    * password: `admin`

    <!-- spellchecker-disable -->
    {{< img name="obaas-apisix-login" size="tiny" lazy=false >}}
    <!-- spellchecker-enable -->

## Expose Spring application through API Gateway and Load Balancer

Now that the application is running, you want to expose it to the outside world.  This is done by creating something called a "route" in the APISIX API Gateway.

1. Create a Route to the Service

    * Then click on the "Routes" option in the menu on the left hand side.

        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

    * Click on the "Create" button to create a new route.
    * Fill out the following details (anything not mentioned here can be left at the default value):
        * name = slow
        * path = /fruit*
        * method = get, options
        * upstream type = service discovery
        * discovery type =eureka
        * service name = SLOW     (note that this is case sensitive, it is on Eureka Service dashboard)

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

    * Save the route you created.
        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes-step4" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
        </br>
        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes-step5" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
        </br>

2. Test a Route to the Service

    * Get the APISIX Gateway External IP

        ```shell
        kubectl --namespace apisix get ingress/apisix-gateway
        ```

    * Call API using APISIX Gateway address plus path

        ```shell
        curl http://APISIX_IP/fruit
        ```

        You should get "banana" or "fallback fruit is apple" back as the response.
