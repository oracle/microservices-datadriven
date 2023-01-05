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

Oracle Backend as a Service for Spring Cloud is available in the [OCI Marketplace](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/138899911).

## Prerequisites

You must meet the following prerequisites to use Oracle Backend as a Service for Spring Cloud:

- An OCI account in a tenancy with sufficient quota to create:
  - An OCI Container Engine for Kubernetes cluster, plus a node pool with three worker nodes
  - A VCN with at least two public IP's available
  - A public load balancer
  - An Oracle Autonomous Database - Shared instance
- At least one free OCI Auth Token (note that the maximum is two per user)

- On local workstation:
  - The Kubernetes command-line tool (kubectl)
  - Oracle Clound Infrastructure Command Line Interface (CLI)
  - Oracle Backend as a Service for Spring Cloud command-line tool

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

## Setup the OCI environment

1. Go to the [OCI Marketplace listing for Oracle Backend as a Service for Spring Cloud](https://cloud.oracle.com/marketplace/application/138899911).

    <!-- spellchecker-disable -->
    ![OCI Marketplace listing](../ebaas-mp-listing.png)
    <!-- spellchecker-enable -->

    Choose the target compartment, agree to the terms and click on the "Launch Stack" button.  This will start the wizard
    to create the new stack. On the first page choose a compartment to host your stack and select `Next`

    <!-- spellchecker-disable -->
    ![OCI Stack wizard page 1](../ebaas-stack-page1.png)
    <!-- spellchecker-enable -->

    Fill in the following configuration variables as needed and select `Next`

    - `Application Name` (Optional)
    - OKE Control Plane Options.
        - `Public Control Plane`: this option allows access the OKE Control Plane from the Internet (Public IP). If not selected, access
          will only be from a private VCN.
        - `Control Plane Access Control`: CIDR (IP range) allowed to access the control plane (Oracle recommends you set this as restrictive as possible).
        - `Enable Horizontal Pod Scaling?`: The [Horizontal Pod Autoscaler](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengusinghorizontalpodautoscaler.htm#Using_Kubernetes_Horizontal_Pod_Autoscaler) can help applications scale out to meet increased demand, or scale in when resources are no longer needed.
        - `Node Pool Workers`: Number of Kubernetes worker nodes (virutal machines) to attach to the OKE Cluster.

    <!-- spellchecker-disable -->
    {{< img name="oci-private-template-create-stack-config" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    Now you can review the stack configuration and save the changes.  Oracle recommends that you do not check the "Run apply" option - this will
    give you the opportunity to run the "plan" first and check for issues.

    <!-- spellchecker-disable -->
    {{< img name="oci-private-template-create-stack-config-review" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

2. Apply the Stack

    After you create your stack, you will be able to test the plan, edit the stack, and apply or destroy the stack.

    Oracle recommends you test the plan before applying the stack, in order to identify any issues before you start
    creating resources.   Testing a plan does not create any actual resources, it is just a "dry run" to tell you
    what would happen if you applied.

    You can test the plan by clicking on the "Plan" button and then reviewing the output.  If you see any
    issues, for example you may find that you do not have enough quota for some resource, you can fix that issue before
    proceeding.

    When you are happy with the results of the test, you can apply the stack by clicking on the "Apply" button. This will create your Oracle Backend
    as a Service for Spring Cloud Environment.  This takes about 20 minutes to complete.  A lot of this time is spent provisioning the
    Kuberentes cluster, worker nodes, and database.  You can watch the logs to follow progress of the operation.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    The OCI Resource Manager will apply your stack and generate the execution logs.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply-logs" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## Setup the local workstation

1. Setting Up Cluster Access

    To access a cluster using kubectl installed (see the [Kubernetes access](./cluster-access)) locally. If you haven't already done so,

    - install kubectl (see the [kubectl documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/)).
    - generate an API signing key pair
        If you already have an API signing key pair, go straight to the next step. If not:

        1. Use OpenSSL commands to generate the key pair in the required PEM format. If you're using Windows, you'll need to install Git Bash for Windows and run the commands with that tool. See [How to Generate an API Signing Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two).
        2. Copy the contents of the public key to the clipboard (you'll need to paste the value into the Console later).

    - add the public key value of the API signing key pair to the User Settings for your username
       1. In the top-right corner of the Oracle Cloud Infrastructure Console, open the **Profile** menu (User menu icon) and then click **User Settings** to view the details.
       2. Click **Add Public Key**.
       3. Paste the public key's value into the window and click **Add**.

          The key is uploaded and its fingerprint is displayed (for example, d1:b2:32:53:d3:5f:cf:68:2d:6f:8b:5f:77:8f:07:13).

    - install and configure the Oracle Cloud Infrastructure CLI
        1. Install the Oracle Cloud Infrastructure CLI version 2.6.4 (or later). See [Quickstart](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#Quickstart).
        2. Configure the Oracle Cloud Infrastructure CLI. See [Configuring the CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Configuring_the_CLI).


2. Install Oracle Backend as a Service for Spring Cloud command-line

    The **Oracle Backend as a Service for Spring Cloud** command-line tool, `obaas`, is available for Linux and Mac systems. Download the binary you want from the [Releases](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0) page and add it to your PATH environment variable.  You may like to rename the binary to remove the suffix.

    If you're environment is a Linux or Mac machine you need to run `chmod +x` on the downloaded binary. Also if your environment is a Mac you need run the following command `sudo xattr -r -d com.apple.quarantine <downloaded-file>` otherwise will you get a security warning and the CLI will not work.
