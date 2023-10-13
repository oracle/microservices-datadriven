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

The Oracle Backend for Spring Boot and Microservices metrics stack automates metrics aggregation and consists of Prometheus and Grafana components.
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
