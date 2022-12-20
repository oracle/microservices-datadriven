---
title: "Jaeger Tracing"
linkTitle: Jaeger Tracing
description: "Configure Jaeger to capture application traces"
resources:
  - name: obaas-jaeger-ui
    src: "obaas-jaeger-ui.png"
    title: "Jaeger UI"
  - name: obaas-jaeger-customer-tracing
    src: "obaas-jaeger-customer-tracing.png"
    title: "Jaeger Customer Tracing"
  - name: obaas-jaeger-customer-trace-details
    src: "obaas-jaeger-customer-trace-details.png"
    title: "Jaeger Customer Tracing Details"

weight: 1
draft: false
---

Jaeger is a distributed tracing system used for monitoring and troubleshooting microservices.
For more information on Jaeger, see the [Jaeger website](https://www.jaegertracing.io/).

## View application traces in Jaeger UI

1. Exposing Jaeger UI using `port-forward`

    ```shell
    kubectl -n observability port-forward svc/jaegertracing-query 16686:16686
    ```

2. Open the Jaeger UI URL: <http://localhost:16686>

    <!-- spellchecker-disable -->
    {{< img name="obaas-jaeger-ui" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

3. In the Jaeger UI, the `Search` Tab allow you list tracings using diverse criterias. Let's test with Customer Microservice

    * Select Service `customer` and Operation `/api/v1/customers`
    * Click on the search button -- Several traces will appear (one for each time you curl'ed)

        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-tracing" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

    * Click on any one of them to view the trace that include multiple services and going into the DB and AQ

        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-trace-details" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
