---
title: Setup
resources:
  - name: oci-private-templates
    src: "oci-private-templates.png"
    title: "Oracle Cloud Infrastructure Private Templates"
  - name: oci-private-template-details
    src: "oci-private-template-details.png"
    title: "Private Template Details"
  - name: oci-private-template-download
    src: "oci-private-template-download.png"
    title: "Download Private Template"
  - name: oci-private-template-create-stack
    src: "oci-private-template-create-stack.png"
    title: "Create Stack from Private Template"
  - name: oci-private-template-create-stack-info
    src: "oci-private-template-create-stack-info.png"
    title: "Create Stack Wizard Information"
  - name: oci-private-template-create-stack-config
    src: "oci-private-template-create-stack-config.png"
    title: "Create Stack Wizard Config Variables"
  - name: oci-private-template-create-stack-config-review
    src: "oci-private-template-create-stack-config-review.png"
    title: "Create Stack Wizard Config Review"
  - name: oci-stack-apply
    src: "oci-stack-apply.png"
    title: "Create Stack Apply"
  - name: oci-stack-apply-logs
    src: "oci-stack-apply-logs.png"
    title: "Create Stack Apply Logs"
---

## Prerequisites

You must meet the following prerequisites to use Oracle Backend as a Service for Spring Cloud:

- An OCI account in a tenancy with sufficient quota to create:
- An OCI Container Engine for Kubernetes cluster, plus a node pool with three worker nodes
- A VCN with at least two public IP's available
- A public load balancer
- An Oracle Autonomous Database - Shared instance
- At least one free OCI Auth Token (note that the maximum is two per user)


## Summary of components

Oracle Backend as a Service for Spring Cloud setup will install the following components:

| Component                    | Version      | Description                                                                              |
|------------------------------|--------------|------------------------------------------------------------------------------------------|
| cert-manager                 | 1.10.1       | Automates the management of certificates.                                                |
| NGINX Ingress Controller     | 1.5.1        | Traffic management solution for cloud‑native applications in Kubernetes.                 |
| Prometheus                   | 2.40.2       | Provides event monitoring and alerting.                                                  |
| Prometheus Operator          | 0.60.1       | Provides management for Prometheus monitoring tools.                                     |
| OpenTelemetry Collector      | 0.66.0       | Collects process and export telemetry data.                                              |
| Grafana                      | 9.2.5        | Tool to help you examine, analyze, and monitor metrics.                                  |
| Jaeger Tracing               | 1.37.0       | Distributed tracing system for monitoring and troubleshooting distributed systems.       |
| APISIX                       | 2.15.1       | Provides full lifecycle API Management.                                                  |
| Spring Admin Server          | 2.7.5        | Managing and monitoring Spring Boot applications.                                        |
| Spring Cloud Config Server   | 2.7.5        | Provides server-side support for externalized configuration.                             |
| Eureka Service Registry      | 2021.0.3     | Provides Service Discovery capabilities                                                  |


## Setup the environment

1. Go to the [OCI Marketplace listing for Oracle Backend as a Service for Spring Cloud]().

    **replace this with oci mp image**
    <!-- spellchecker-disable -->
    {{< img name="oci-private-template-create-stack" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    This will start the wizard to create the new stack. On the first page please choose a compartment to host your stack and select `Next`

    <!-- spellchecker-disable -->
    {{< img name="oci-private-template-create-stack-info" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    Fill the configuration variables and select `Next`

    * `Application Name` (Optional)
    * OKE Control Plane Options.
        * `Public Control Plane`: this option allow you access the OKE Control Plane from the Internet (Public IP)
        * `Control Plane Access Control`: IP range enabled to access the control plane (recommended)
        * `Enable Horizontal Pod Scaling?`: The [Horizontal Pod Autoscaler](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengusinghorizontalpodautoscaler.htm#Using_Kubernetes_Horizontal_Pod_Autoscaler) can help applications scale out to meet increased demand, or scale in when resources are no longer needed.
        * `Node Pool Workers`: Number of VMs of the OKE Cluster.

    <!-- spellchecker-disable -->
    {{< img name="oci-private-template-create-stack-config" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    Now you can review the stack configuration and save the changes. Please, *DO NOT* check the `Run apply` box

    <!-- spellchecker-disable -->
    {{< img name="oci-private-template-create-stack-config-review" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

3. Apply the Stack from the OBaaS Template

    After you create your Stack, you will be able to test the Plan, Edit the Stack, Apply the Stack or Destroy.

    We recommend you test the Plan before apply the stack, the objective is review the plan and prevent run in issues.

    After plan test, you can apply the stack and create your OBaaS Environment.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    The OCI Resource Manager will apply your stack and generate the execution logs.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply-logs" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## Get access to the OBaaS OKE Cluster and ADB

After create the OBaaS Environment, you will have get access to Autonoums Database and OKE Cluster to create the Database objects and deploy the sample applications.

1. Create Dynamic port forwarding (SOCKS5) session using Bastion service.

    Let's start with ADB access that was created with private end point access only following security guidance. To allow you get access to ADB to execute sql commnads you will need to stablish an session between your local workstation and ADB passing by the Bastion service.

    We will create a [Dynamic port forwarding (SOCKS5) session](https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingsessions.htm#).

    <!-- spellchecker-disable -->
    {{< img name="oci-bastion-session-create" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    After session create you will be able to stablish the tunnel with your ADB Instance issuing a SSH command that you can obtain clicking on three dots menu on right side of the session created.

    ```shell
    ssh -i <privateKey> -N -D 127.0.0.1:<localPort> -p 22 ocid1.bastionsession.oc1.phx....@host.bastion.us-phoenix-1.oci.oraclecloud.com
    ```

2. Connect with ADB Instance using SQLcl

    With tunnel stablished, you will be able to connect with ADB instance. First export the Oracle Net port executing the next commmand:

    ```shell
    <copy>
    export CUSTOM_JDBC="-Doracle.net.socksProxyHost=127.0.0.1 -Doracle.net.socksProxyPort=<PORT> -Doracle.net.socksRemoteDNS=true"
    </copy>
    ```

    Download ADB client credentials (Wallet):

    <!-- spellchecker-disable -->
    {{< img name="oci-adb-download-wallet" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    Connect with SQLcl

    ```shell
    sql /nolog
    ```

    ```sql
    set cloudconfig <WALLET>.zip
    connect ADMIN@<ADB SERVICE>
    ```

3. Connect with OKE Instance

    To deploy Sample Applications to OBaaS OKE Cluster, you should setup your local Kubectl following the [Setting Up Cluster Access](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#localdownload) documentation.
