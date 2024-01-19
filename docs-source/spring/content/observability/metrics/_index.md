---
title: "Metrics"
description: "Prometheus metrics and Grafana dashboards for Spring Boot applications with the Oracle Backend for Spring Boot and Microservices"
keywords: "observability metrics prometheus grafana spring springboot microservices development oracle backend"
resources:
  - name: metrics
    src: "metrics.png"
    title: "Metrics"
  - name: obaas-prometheus-ui
    src: "obaas-prometheus-ui.png"
    title: "Prometheus UI"
  - name: obaas-prometheus-home
    src: "obaas-prometheus-home.png"
    title: "Prometheus Metrics"
  - name: obaas-prometheus-targets
    src: "obaas-prometheus-targets.png"
    title: "Prometheus Targets"
  - name: obaas-grafana-login
    src: "obaas-grafana-login.png"
    title: "Grafana Login"
  - name: obaas-grafana-datasource
    src: "obaas-grafana-datasource.png"
    title: "Grafana Datasource"
  - name: obaas-grafana-import-dashboard
    src: "obaas-grafana-import-dashboard.png"
    title: "Grafana Import Dashboard"
  - name: obaas-grafana-dashboard
    src: "obaas-grafana-dashboard.png"
    title: "Grafana Dashboard"
  - name: db-dashboard
    src: "db-dashboard.png"
    title: "Oracle Database Dashboard"
  - name: spring-boot-observability-dashboard
    src: "spring-boot-observability-dashboard.png"
    title: "Spring Boot Observablity Dashboard"
  - name: spring-boot-stats-dashboard
    src: "spring-boot-stats-dashboard.png"
    title: "Spring Boot Statistics Dashboard"
  - name: kube-state-metrics-dashboard
    src: "kube-state-metrics-dashboard.png"
    title: "Kube State Metrics Dashboard"
---

Oracle Backend for Spring Boot and Microservices provides built-in platform services to collect metrics from system and application
workloads and pre-built Grafana dashboards to view and explore those metrics. 

## Pre-installed dashboards

The following dashboards are pre-installed in Grafana:

### Spring Boot Observability

This dashboard ...

<!-- spellchecker-disable -->
{{< img name="spring-boot-observability-dashboard" size="medium" lazy=false >}}
<!-- spellchecker-enable -->


### Spring Boot Statistics

This dashboard ...

<!-- spellchecker-disable -->
{{< img name="spring-boot-stats-dashboard" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

### Oracle Database Dashboard

This dashboard ...

<!-- spellchecker-disable -->
{{< img name="db-dashboard" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

### Kube State Metrics Dashboard

This dashboard ...

<!-- spellchecker-disable -->
{{< img name="kube-state-metrics-dashboard" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

## How to have metrics collected for your applications 

When you deploy an application with Oracle Backend for Spring Boot and Microservices CLI or
Visual Code Extension, provided you included the Eureka Discovery Client and Actuator in your application,
Prometheus will automatically find your application (using the service registry) and start
collecting metrics.  These metrics will be included in both the Spring Boot Observability
dashboard and the Spring Boot Statistic dashboard automatically.

To include the Eureka Discovery client in your application, add the following dependencies
to your Maven POM or equivalent:

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

You must also add the following configuration to your Spring `application.yaml`:

```yaml
spring:
  application:
    name: my-app

eureka:
  instance:
    hostname: ${spring.application.name}
    preferIpAddress: true
  client:
    service-url:
      defaultZone: ${eureka.service-url}
    fetch-registry: true
    register-with-eureka: true
    enabled: true

management:
  endpoint:
    health:
      show-details: always
  endpoints:
    web:
      exposure:
        include: "*"
  metrics:
    tags:
      application: ${spring.application.name}    
```

Alternatively, if you do not want to include the Eureka client, you can instead create
a `ServiceMonitor` resource for your service. This must be created in the namespace where
your application is deployed, and you must specify the correct port and the path for
Spring Boot Actuator.  Your application must have Actuator and the `prometheus` endpoint
enabled, as described above.

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: my-app
  name: my-app
  namespace: application
spec:
  endpoints:
  - interval: 20s
    path: /actuator/prometheus
    port: 8080
  selector:
    matchLabels:
      app: my-app
```

## Something


stack automates metrics aggregation and consists of Prometheus and Grafana components.
Metrics sources expose system and application metrics. The Prometheus components retrieve and store the metrics and Grafana provides
dashboards to visualize them.

<!-- spellchecker-disable -->
{{< img name="metrics" size="small" lazy=false >}}
<!-- spellchecker-enable -->

## View Metrics From the Application in Prometheus

Prometheus is an open source monitoring and alerting system. Prometheus collects and stores metrics as time series data with the timestamp of
the time that they are recorded, and optional Key/Value pairs called labels.

1. Expose the Prometheus user interface (UI) using this command:

    ```shell
    kubectl port-forward -n prometheus svc/prometheus 9090:9090
    ```

2. Open the Prometheus web user interface URL: <http://localhost:9090>

    <!-- spellchecker-disable -->
    {{< img name="obaas-prometheus-ui" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

3. In the Prometheus web user interface, search for metrics:

   * In the search bar, search for `application_ready_time_seconds` and click on **Execute**.
   * You should see metrics for the Sample Applications.
   
   For example:

    <!-- spellchecker-disable -->
    {{< img name="obaas-prometheus-home" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

4. In the Prometheus web user interface, **Status** allows you to view the targets being monitored by Prometheus:

    * In the top menu, choose **Status** and then **Targets**.
    * Notice that the targets "slow", "customer" and others are in **UP** status and others are in **DOWN** status.

    <!-- spellchecker-disable -->
    {{< img name="obaas-prometheus-targets" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## View Details of the Application in Grafana

[Grafana](https://grafana.com/docs/grafana/latest/introduction/) open source software enables you to query, visualize, alert, and explore your
metrics, logs, and traces wherever they are stored. Grafana open source software provides tools that turn your time series database (TSDB) data
into insightful graphs and visualizations. Take the following steps:

1. Expose Grafana using this command:

    ```shell
    kubectl -n grafana port-forward svc/grafana 8080:80
    ```

2. Open the Grafana web user interface URL: <http://localhost:8080>

    * username: `admin`
    * To get the password, run this command:

      ```shell
      kubectl -n grafana get secret grafana -o jsonpath='{.data.admin-password}' | base64 -d
      ```

      > **NOTE:** If you do not have `base64`, leave off the last part (`| base64 -d`) in the command, then copy the output, and use this
	  website to decode it: <https://www.base64decode.org/>.
		
	  The password is a long string of characters that might be similar to `210BAqNzYkrcWjd58RKC2Xzerx9c0WkZi9LNsG4c`. For example:

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-login" size="small" lazy=false >}}
    <!-- spellchecker-enable -->

3. Set up the Prometheus data source:

    a. At the lower left, click on the system setup symbol and choose **Data Sources**.

    b. Click on the second data source called **Prometheus** and in the address (be careful to get the address field, not the name field), change
      the address from <http://prometheus:9090> to <http://prometheus.prometheus.svc.cluster.local:9090>.
      
    c. At the bottom of the page, click **Save & Test** and wait for 2-3 seconds for the green icon which indicates that the data source is working.

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-datasource" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

4. Set up the dashboard:

    a. In the upper left, find and click the **dasbhoards** link.

    b. Click on the blue button to the right to add a new dashboard. In the pull down menu, select **Import**.

    c. In the field for the Grafana dashboard ID, paste this value: `10280`.

    d. Click **Next**.

    e. In the data source field, select **Prometheus**.

    f. Click **Save**.

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-import-dashboard" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

5. Navigate the Spring Boot dashboard:

    a. You should see the new dashboard in the list called **Spring Boot Dashboard 2.1**. Click on it to open.

    b. You should automatically see details for the Sample Applications in the dashboard.
    
    c. Invoke the service. For example, use a `curl` command to create some traffic and observe the dashboard. You may need to repeat
	   the `curl` command. There is a refresh symbol in the top right corner that enables automatic refresh every 5 seconds (or, for
	   whatever length of time that you choose).

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-dashboard" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->
	
Next, go to the [Tracing](../observability/tracing/) page to learn more.
