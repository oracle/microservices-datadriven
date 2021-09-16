# Building Microservices with Oracle Converged Database On-Premises Workshop

Describe the application here,...

    For additional details regarding Microservices Data-driven applications on Oracle Converged Database check,

    https://github.com/oracle/microservices-datadriven



[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/vishalmmehra/microservices-datadriven/raw/main/infra/multi-node-deployment.zip)

<details>

<summary> 
   Lab 2:
   </summary>

Complete the Setup Instructions
</details>

<details>

<summary> 
   Lab 3: Polyglot Microservices
   </summary>

The illustration below shows four microservices – Order, Inventory, Delivery, Supplier, and the infrastructure required to run them.

![img.png](images/img.png)

For more information on microservices visit http://developer.oracle.com/microservices

This lab will show you how to switch the Inventory microservice to a Python, Node.js, .NET, Go, Spring Boot or Java Helidon SE implementation while retaining the same application functionality.

Estimates Lab Time - 10 minutes

**Objectives**

Undeploy the existing Java Helidon MP Inventory microservice
Deploy an alternate implementation of the Inventory microservice and test the application functionality

**Prerequisites**

This lab assumes you have already completed the previous labs.

<details>
<summary>Task 1: Undeploy the Java Helidon MP Inventory Microservice</summary> 

To undeploy the Inventory Helidon MP service, open the Cloud Shell and go to the inventory-helidon folder, using the following command.

`$GRABDISH_HOME/inventory-helidon ; ./undeploy.sh`
</details>

<details>
<summary>Task 2: Deploy an alternate implementation of the Inventory Microservice</summary>

In this step you can choose between six different implementations of the Inventory Microservice: PL/SQL, Python, NodeJS, .NET, Go, or Java Helidon SE.

Select one of the alternate implementations and deploy the service for the selected implementation.

If you selected PL/SQL, deploy this service:

`cd $GRABDISH_HOME/inventory-plsql; ./deploy.sh`

If you selected Python, deploy this service:

`cd $GRABDISH_HOME/inventory-python; ./deploy.sh`

If you selected Node.js, deploy this service:

`cd $GRABDISH_HOME/inventory-nodejs; ./deploy.sh`

If you selected .NET, deploy this service:

`cd $GRABDISH_HOME/inventory-dotnet; ./deploy.sh`

If you selected Go, deploy this service:

`cd $GRABDISH_HOME/inventory-go; ./deploy.sh`
If you selected Spring Boot, deploy this service:

`cd $GRABDISH_HOME/inventory-springboot; ./deploy.sh`
If you selected Java Helidon SE, deploy this service:

`cd $GRABDISH_HOME/inventory-helidon-se; ./deploy.sh`
</details>

<details>
<summary>Task 3: Verify application functionality</summary>

Repeat Lab 2: Step 3 to verify that the functionality of the GrabDish store remains the same while using the new implementation. You will need to use different order ID's, for example 166 and 167.
Task 4: Re-deploy the Java Helidon MP Inventory Microservice
To undeploy any other inventory services and then deploy the Inventory Helidon MP service, issue the following commands.

`for i in inventory-plsql inventory-helidon-se inventory-python inventory-nodejs inventory-dotnet inventory-go inventory-springboot; do cd $GRABDISH_HOME/$i; ./undeploy.sh; done
cd $GRABDISH_HOME/inventory-helidon ; ./deploy.sh
cd $GRABDISH_HOME`

</details>

</details>

<details>
<summary> 
   Lab 4: Observability (Metrics, Tracing, and Logs)
   </summary>

<details>
<summary> Task 1: Install and configure observability software as well as metrics and log exporters</summary>


Run the install script to install Jaeger, Prometheus, Loki, Promtail, Grafana and an SSL secured LoadBalancer for Grafana

`cd $GRABDISH_HOME/observability;./install.sh`

Run the /createMonitorsAndDBAndLogExporters.sh script. This will do the following…

Create Prometheus ServiceMonitors to scrape the Frontend, Order, and Inventory microservices.

Create Prometheus ServiceMonitors to scrape the Order PDB, and Inventory PDB metric exporter services.

Create configmpas, deployments, and services for PDB metrics exporters.

Create configmaps, deployments, and services for PDB log exporters.

`cd $GRABDISH_HOME/observability;./createMonitorsAndDBAndLogExporters.sh`

</details>

<details>

<summary>Task 2: Configure Grafana </summary>
Identify the EXTERNAL-IP address of the Grafana LoadBalancer by executing the following command:

`services`


Note that it will generally take a few minutes for the LoadBalancer to provision during which time it will be in a pending state

Open a new browser tab and enter the external IP URL :

https://<EXTERNAL-IP>

Note that for convenience a self-signed certificate is used to secure this https address and so it is likely you will be prompted by the browser to allow access.

Login using the default username admin and password prom-operator

![img_1.png](images/img_1.png)

View pre-configured Prometheus data source…

![img_2.png](images/img_2.png)

Select the Configuration gear icon on the left-hand side and select Data Sources.

![img_3.png](images/img_3.png)


Click select button of Prometheus option.

![img_4.png](images/img_4.png)

The URL for Prometheus should be pre-populated

![img_5.png](images/img_5.png)


Click Test button and verify success.

![img_6.png](images/img_6.png)

Click the Back button.

Select the Data sources tab and select Jaeger

Click Add data source.

![img_7.png](images/img_7.png)

Click select button of Jaeger option.

![img_8.png](images/img_8.png)

Enter http://jaeger-query.msdataworkshop:8086/jaeger in the URL field.

![img_9.png](images/img_9.png)

Click the Save and test button and verify successful connection message.

![img_10.png](images/img_10.png)

Click the Back button.

![img_11.png](images/img_11.png)

Add and configure Loki data source…

Click Add data source.

![img_12.png](images/img_12.png)

Click select button of Loki option.

![img_13.png](images/img_13.png)

Enter http://loki-stack.loki-stack:3100 in the URL field

![img_14.png](images/img_14.png)

Create the two Derived Fields shown in the picture below. The values are as follows:

Name: traceIDFromSpanReported
Regex: Span reported: (\w+)
Query: ${__value.raw}
Internal link enabled and `Jaeger` selected from the drop-down list.
(Optional) Debug log message: Span reported: dfeda5242866aceb:b5de9f0883e2910e:ac6a4b699921e090:1

Name: traceIDFromECID
Regex: ECID=(\w+)
Query: ${__value.raw}
Internal link enabled and `Jaeger` selected from the drop-down list
(Optional) Debug log message: ECID=dfeda5242866aceb

![img_15.png](images/img_15.png)

![img_16.png](images/img_16.png)


Click the Save & Test button and verify successful connection message.

![img_17.png](images/img_17.png)

Click the Back button.

Install the GrabDish Dashboard

Select the + icon on the left-hand side and select Import

![img_18.png](images/img_18.png)

Copy the contents of the GrabDish Dashboard JSON found here

![img_19.png](images/img_19.png)

Paste the contents in the Import via panel json text field and click the Load button

![img_20.png](images/img_20.png)

Confirm upload and click Import button.

![img_21.png](images/img_21.png)

</details>

<details>

<summary> Task 3: Open and study the main GrabDish Grafana Dashboard screen and metrics</summary>

Select the four squares icon on the left-hand side and select 'Dashboards'

![img_22.png](images/img_22.png)

In the Dashboards panel select GrabDish Dashboard

![img_23.png](images/img_23.png)

Notice the collapsible panels for each microservices and their content which includes

![img_24.png](images/img_24.png)

Metrics about the kubernetes microservice runtime (CPU load, etc.)

Metrics about the kubernetes microservice specific to that microservice (PlaceOrder Count, etc.)

Metrics about the PDB used by the microservice (open sessions, etc.)

Metrics about the PDB specific to that microservice (inventory count)

![img_25.png](images/img_25.png)

![img_26.png](images/img_26.png)

![img_27.png](images/img_27.png)



By default the status will show a value of 1 for UP status.

![img_28.png](images/img_28.png)

This can be corrected by selecting the Edit item in the/a Status panel dropdown

![img_29.png](images/img_29.png)

Add a value mapping where value of 1 results in text of UP) under the Field tab as shown here:

![img_30.png](images/img_30.png)

Click the Apply button in the upper right to apply changes.

If not already done, place an order using the application or run the scaling test in previous labs in order to see the metric activity in the dashboard.

Select the 'Explore' option from the drop-down menu of any panel to show that metric and time-span on the Explore screen

![img_31.png](images/img_31.png)

</details>

<details>
<summary>Task 4: Use Grafana to drill down on metrics, tracing, and logs correlation and logs to trace feature<summary>Task 4: Use Grafana to drill down on metrics, tracing, and logs correlation and logs to trace feature<summary>Task 4: Use Grafana to drill down on metrics, tracing, and logs correlation and logs to trace feature</summary>

Click the Split button on the Explore screen.

![img_32.png](images/img_32.png)

Click the Loki option from the drop-down list on the right-hand panel.

![img_33.png](images/img_33.png)

Click the chain icon on either panel. This will result in the Prometheus metrics on the left and Loki logs on the right are of the same time-span.

![img_34.png](images/img_34.png)

Click the Log browser drop-down list on the right-hand panel and select the app label under "1. Select labels to search in"

![img_35.png](images/img_35.png)

Select the order (microservice) and db-log-exporter-orderpdb values under "2. Find values for selected label" and click Show logs button.

![img_36.png](images/img_36.png)

![img_37.png](images/img_37.png)



Select one of the green info log entries to expand it. Notice the Jaeger button next to the trace id.

![img_38.png](images/img_38.png)

Click the Jaeger to view the corresponding trace information and drill down into detail.

![img_39.png](images/img_39.png)

</details>

</details>

<details>
<summary> 
   Lab 5: Teardown
   </summary>

**Introduction**
In this lab, we will tear down the resources created in your tenancy and the directory in the Oracle cloud shell.
Objectives
Clone the setup and microservices code
Execute the setup
Prerequisites
Have successfully completed the previous labs
</details>

