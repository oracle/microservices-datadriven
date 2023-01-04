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

## View application traces in Jaeger web user interface

1. Exposing Jaeger web user interface using `port-forward`

    ```shell
    kubectl -n observability port-forward svc/jaegertracing-query 16686:16686
    ```

2. Open the Jaeger web user interface URL: <http://localhost:16686>

    <!-- spellchecker-disable -->
    {{< img name="obaas-jaeger-ui" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

3. In the Jaeger web user interface, the `Search` Tab allows you find tracings using various criteria. For example, to find
   traces for the customer microservice included in the sample apps:

    * If you deployed the [sample apps](../../sample-apps), exposed the customer service through the APISIX Gateway and called it at least once, you will
      be able to find traces for it in Jaeger.
    * Select Service `customer` and Operation `/api/v1/customers`
    * Click on the search button -- Several traces will appear (one for each time you invoked the service)

        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-tracing" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

    * Click on any one of them to view the trace that include multiple services and extends into the Oracle database and Oracle Advanced Queueing:

        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-trace-details" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->
