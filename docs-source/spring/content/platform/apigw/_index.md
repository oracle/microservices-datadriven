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

[Apache APISIX](https://apisix.apache.org) is an open-source cloud native API platform that supports the full lifecycle of API management including publishing, traffic management, deployment strategies, and circuit breakers.

## Deploy and Secure Sample Apps APIs using APISIX

Oracle Backend for Spring Boot deploys APISIX Gateway and Dashboard in the `apisix` namespace. The gateway is exposed through the external load balancer and ingress controller.  To access the APISIX Dashboard, you must use `kubectl port-forward` to create a secure channel to `service/apisix-dashboard`.

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

    **Note:** Oracle recommends that you change the default password when you first login.  Even though the dashboard is not accessible externally,
    we still recommend using strong passwords to maximize security.

    <!-- spellchecker-disable -->
    {{< img name="obaas-apisix-login" size="tiny" lazy=false >}}
    <!-- spellchecker-enable -->

## Exposing a Spring application through the API Gateway and Load Balancer

Once you have your application deployed and running, you may want to expose it to the outside world. Some applications may not need to be
exposed if they are only called by other applications in the platform.
To expose your application, you create a "route" in the APISIX API Gateway.

1. Create a Route to the Service

    * In the APISIX Dashboard, click on the "Routes" option in the menu on the left hand side.

        <!-- spellchecker-disable -->
        {{< img name="obaas-apisix-routes" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

    * Click on the "Create" button to create a new route.
    * Fill out the necessary details (anything not mentioned here can be left at the default value). For example, for the "slow service"
      included in the [sample apps](../../sample-apps):
        * name = slow
        * path = /fruit*
        * method = get, options
        * upstream type = service discovery
        * discovery type = eureka
        * service name = SLOW     (note that this is case sensitive, this is the key from the Eureka dashboard)

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

    * Get the APISIX Gateway External IP using this command:

        ```shell
        kubectl -n ingress-nginx get svc ingress-nginx-controller
        ```

    * Call API using APISIX Gateway address plus path:

        ```shell
        curl http://APISIX_IP/fruit
        ```

        You should get "banana" or "fallback fruit is apple" back as the response.
