---
title: "Metrics"
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
---

The Oracle Backend as a Service for Spring Cloud metrics stack automates metrics aggregation and consists of Prometheus and Grafana components.
Metrics sources expose system and application metrics.
The Prometheus components retrieve and store the metrics and Grafana provides dashboards to
visualize them.

<!-- spellchecker-disable -->
{{< img name="metrics" size="small" lazy=false >}}
<!-- spellchecker-enable -->

## View metrics from the application in Prometheus

Prometheus is an open-source systems monitoring and alerting. Prometheus collects and stores its metrics as time series data, i.e. metrics information is stored with the timestamp at which it was recorded, alongside optional key-value pairs called labels.

1. Exposing Prometheus UI using `port-forward`

    ```shell
    kubectl port-forward -n prometheus svc/prometheus 9090:9090
    ```

2. Open the Prometheus UI URL: <http://localhost:9090>

    <!-- spellchecker-disable -->
    {{< img name="obaas-prometheus-ui" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

3. In the Prometheus UI, home page you can search for metrics.

    * In the search bar, search for application_ready_time_seconds and hit Execute
    * Notice you see metrics for the sample applications

    <!-- spellchecker-disable -->
    {{< img name="obaas-prometheus-home" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

4. In the Prometheus UI, the `Status` Menu Item allow you list all targets being monitored by Prometheus.

    * In the top menu, choose Status and then Targets
    * Notice targets "slow", "customer" and others are in "UP" status and others are in "Down".

    <!-- spellchecker-disable -->
    {{< img name="obaas-prometheus-targets" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## View details of the application in Grafana

[Grafana](https://grafana.com/docs/grafana/latest/introduction/) open source software enables you to query, visualize, alert on, and explore your metrics, logs, and traces wherever they are stored. Grafana OSS provides you with tools to turn your time-series database (TSDB) data into insightful graphs and visualizations.

1. Exposing Grafana using `port-forward`

    ```shell
    kubectl -n grafana port-forward svc/grafana 8080:80
    ```

2. Open the Grafana UI URL: <http://localhost:8080>

    * username: `admin`
    * To get the password run this command:

        ```shell
        kubectl -n grafana get secret grafana -o jsonpath='{.data.admin-password}' | base64 -d
        ```

        > **Note:** If you don't have "base64" leave off the last part ("| base64 -d") and then copy the output and use this website to decode it: <https://www.base64decode.org/>. The password will be a long string of characters like this 210BAqNzYkrcWjd58RKC2Xzerx9c0WkZi9LNsG4c (yours will be different)

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-login" size="small" lazy=false >}}
    <!-- spellchecker-enable -->

3. Setup Prometheus Datasource

    * On the left hand side menu, down the bottom, click on the cog wheel and choose Data Sources
    * Click on the second data source, its called "Prometheus"
    & In the address (be careful to get the address field, not the name field), change the address from  <http://prometheus:9090>    to <http://prometheus.prometheus.svc.cluster.local:9090>
    * Down the bottom of the page click on save & test and wait for the green icon to say the datasource is working (takes 2-3 seconds)

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-datasource" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

4. Setup Dashboard

    * Now in the left hand side menu up the top, find the dasbhoards link and click on that
    * Click on the blue button on the right to add a new dashboard, and in the pull down select "import"
    * In the field for the grafana dashboard ID, paste in this value: `10280`
    * Click on next
    * In the datasource field, choose the one called "prometheus"
    * Click on save

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-import-dashboard" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->

5. Navigate in Spring Boot Dashboard

    * Now you should see the new dashboard in the list - its called Spring Boot Dashboard 2.1 - click on it to open it
    * You should automatically see details for the sample applications in the dashboard
    * Go and do a few more curls to create some traffic and observe the dashboard - there is a little round arrow thing in the top right corner that lets you tell it to automatically refresh every 5 seconds (or whatever period you choose)

    <!-- spellchecker-disable -->
    {{< img name="obaas-grafana-dashboard" size="medium" lazy=false >}}
    <!-- spellchecker-enable -->
