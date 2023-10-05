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

Jaeger is a distributed tracing system used for monitoring and troubleshooting Microservices.
For more information on Jaeger, see the [Jaeger website](https://www.jaegertracing.io/).

## View Application Traces in Jaeger Web User Interface

1. Expose the Jaeger web user interface using this command:

    ```shell
    kubectl -n observability port-forward svc/jaegertracing-query 16686:16686
    ```

2. Open the Jaeger web user interface URL: <http://localhost:16686>

    <!-- spellchecker-disable -->
    {{< img name="obaas-jaeger-ui" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

3. In the Jaeger web user interface, click the **Search** tab to find tracings using various search criteria. For example, to find
   traces for the customer Microservice included in the Sample Applications:

    a. If you deployed the [Sample Applications](../../sample-apps), exposing the customer service through the Apache APISIX Gateway and
	   called it at least once, you can find traces for it in Jaeger.
	   
    b. Select the **Service** `customer` and the **Operation** `/api/v1/customers` .
	
    c. Click on **Find Traces**. Several traces appear (one for each time that you invoked the service).
        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-tracing" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

    d. Click on any one of them to view the trace that includes multiple services and extends into Oracle Database and Oracle
	   Advanced Queuing. For example:
        <!-- spellchecker-disable -->
        {{< img name="obaas-jaeger-customer-trace-details" size="medium" lazy=false >}}
        <!-- spellchecker-enable -->

