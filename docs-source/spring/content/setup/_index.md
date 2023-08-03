---
title: "Setup"
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
  - name: oci-private-template-create-stack-config-lb-vault
    src: "oci-private-template-create-stack-config-lb-vault.png"
    title: "Create Stack Wizard Config Variables"
  - name: oci-private-template-create-stack-config-review
    src: "oci-private-template-create-stack-config-review.png"
    title: "Create Stack Wizard Config Review"
  - name: oci-stack-plan
    src: "oci-stack-plan.png"
    title: "Create Stack Plan"
  - name: oci-stack-apply
    src: "oci-stack-apply.png"
    title: "Create Stack Apply"
  - name: oci-stack-apply-logs
    src: "oci-stack-apply-logs.png"
    title: "Create Stack Apply Logs"
  - name: oci-stack-outputs
    src: "oci-stack-outputs.png"
    title: "Create Stack Outputs"
  - name: oci-stack-output-oke
    src: "oci-stack-output-oke.png"
    title: "Get Kube Config Cmd"
  - name: oci-stack-db-options
    src: "oci-stack-db-options.png"
    title: "Database Options"
  - name: oci-stack-parse-options
    src: "oci-stack-parse-options.png"
    title: "Parse Server Options"
  - name: oci-stack-app-name
    src: "oci-stack-app-name.png"
    title: "Compartment and Application Name"
  - name: ebaas-mp-listing
    src: "ebaas-mp-listing.png"
    title: "Marketplace Listing"
  - name: ebaas-stack-page1
    src: "ebaas-stack-page1.png"
    title: "Create Stack"
---

Oracle Backend for Spring Boot is available in the [OCI Marketplace](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/138899911).

## Prerequisites

You must meet the following prerequisites to use Oracle Backend for Spring Boot. You need:

- An Oracle Cloud Infrastructure (OCI) account in a tenancy with sufficient quota to create the following:

  - An OCI Container Engine for Kubernetes cluster (OKE cluster), plus a node pool with three worker nodes.
  - A virtual cloud network (VCN) with at least two public IP's available.
  - A public load balancer.
  - An Oracle Autonomous Database Serverless instance.
  
- At least one free OCI auth token (note that the maximum is two per user).

- On a local machine, you need:

  - The Kubernetes command-line interface (kubectl).
  - Oracle Cloud Infrastructure command-line interface (CLI).
  - Oracle Backend for Spring Boot command-line interface (oractl).

## Summary of Components

Oracle Backend for Spring Boot setup installs the following components:

| Component                    | Version       | Description                                                                                 |
|------------------------------|---------------|---------------------------------------------------------------------------------------------|
| cert-manager                 | 1.11.0        | Automates the management of certificates.                                                   |
| NGINX Ingress Controller     | 1.6.4         | Provides traffic management solution for cloud‑native applications in Kubernetes.           |
| Prometheus                   | 2.40.2        | Provides event monitoring and alerts.                                                       |
| Prometheus Operator          | 0.63.0        | Provides management for Prometheus monitoring tools.                                        |
| OpenTelemetry Collector      | 0.66.0        | Collects process and export telemetry data.                                                 |
| Grafana                      | 9.2.5         | Provides the tool to examine, analyze, and monitor metrics.                                 |
| Jaeger Tracing               | 1.39.0        | Provides distributed tracing system for monitoring and troubleshooting distributed systems. |
| Apache APISIX                | 3.2.0         | Provides full lifecycle API management.                                                     |
| Spring Boot Admin server     | 2.7.5         | Manages and monitors Spring Cloud applications.                                             |
| Spring Cloud Config server   | 2.7.5         | Provides server-side support for an externalized configuration.                             |
| Spring Eureka service registry | 3.1.4       | Provides service discovery capabilities.                                                    |
| HashiCorp Vault              | 1.14.0        | Provides a way to store and tightly control access to sensitive data.                       |
| Oracle Database operator     | 1.0           | Helps reduce the time and complexity of deploying and managing Oracle databases.            |
| Oracle Transaction Manager for Microservices | 22.3.1 | Manages distributed transactions to ensure consistency across Microservices.       |
| Strimzi-Apache Kafka operator  | 0.33.1      | Manages Apache Kafka clusters.                                                              |
| Apacha Kafka                 | 3.2.0 - 3.3.2 | Provides distributed event streaming.                                                       |
| Coherence                    | 3.2.11        | Provides in-memory data grid.                                                               |
| Parse Server (optional)      | 6.2.0         | Provides backend services for mobile and web applications.                                  |
| Parse Dashboard (optional)   | 5.1.0         | Provides web user interface for managing the Parse Server.                                  |
| Oracle Database storage adapter for Parse  (optional) | 0.2.0    | Enables the Parse Server to store data in Oracle Database.              |
| Conductor Server             | 3.13.2        | Provides a Microservice orchestration platform.                                             |


## Overview of the Setup Process

This video provides a quick overview of the setup process.

{{< youtube rAi10TiUraE >}}

## Set Up the OCI Environment

To set up the OCI environment, process these steps:

1. Go to the [OCI Marketplace listing for Oracle Backend for Spring Boot](https://cloud.oracle.com/marketplace/application/138899911).

    <!-- spellchecker-disable -->
    {{< img name="ebaas-mp-listing" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    Choose the target compartment, agree to the terms, and click **Launch Stack**.  This starts the wizard and creates the new stack. On
	the first page, choose a compartment to host your stack and select **Next**.

    <!-- spellchecker-disable -->
    {{< img name="ebaas-stack-page1" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

2.  Fill in the following configuration variables as needed and select **Next**:

    - `Compartment` : Select the compartment where you want to install Oracle Backend for Spring Boot.
    - `Application Name` (optional) : A random name that will be used as the application name if left empty.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-app-name" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

3. Fill in the following for the Parse Server:

   - `Application ID` (optional) : Leave blank to auto-generate.
   - `Server Master Key` (optional) : Leave blank to auto-generate.
   - `Dashboard Username` : The user name of the user to whom access to the dashboard is granted.
   - `Dashboard Password` : The password of the dashboard user (a minimum of 12 characters).

     <!-- spellchecker-disable -->
     {{< img name="oci-stack-parse-options" size="large" lazy=false >}}
     <!-- spellchecker-enable -->

4. Fill in the following for the OKE Control Plane options:

   - `Public Control Plane` : This option allows access to the OKE Control Plane from the internet (public IP). If not selected, access can
      only be from a private virtual cloud network (VCN).
   - `Control Plane Access Control` : The Classless Inter-Domain Routing (CIDR) IP range allows access to the Control Plane.
      Oracle recommends that you set this variable to be as restrictive as possible.
   - `Enable Horizontal Pod Scaling?` : The [Horizontal Pod Autoscaler](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengusinghorizontalpodautoscaler.htm#Using_Kubernetes_Horizontal_Pod_Autoscaler)
      helps applications scale out to meet increased demand, or scale in when resources are no longer needed.
   - `Node Pool Workers` : The number of Kubernetes worker nodes (virtual machines) attached to the OKE cluster.
   - `Node Pool Worker Shape` : The shape of the node pool workers.
   - `Node Workers OCPU` : The initial number of Oracle Compute Units (OCPUs) for the node pool workers.

      <!-- spellchecker-disable -->
      {{< img name="oci-private-template-create-stack-config" size="large" lazy=false >}}
      <!-- spellchecker-enable -->

5. Fill in the following for the Load Balancers options:

   - `Enable Public Load Balancer` : This option allows access to the load balancer from the internet (public IP). If not
      selected, access can only be from a private VCN.
   - `Public Load Balancer Ports Exposed` : The ports exposed from the load balancer.
   - `Minimum bandwidth` : The minimum bandwidth that the load balancer can achieve.
   - `Maximum bandwidth` : The maximum bandwidth that the load balancer can achieve.

6. Fill in the following Vault options. You have the option of creating a new OCI Vault or using an existing OCI Vault. Fill in the
   following information if you want to use an existing OCI Vault:
   
   - `Vault Compartment (Optional)` : Select a compartment for the OCI Vault.
   - `Existing Vault (Optional)` : Select an existing OCI Vault.
   - `Existing Vault Key (Optional)` : Select an existing OCI Vault key.
   - `Maximum bandwidth` : The maximum bandwidth that the load balancer can achieve.

   If you unselect `Enable Vault`, the HashiCorp Vault is installed in **Development** mode.

   {{< hint type=[warning] icon=gdoc_check title=Warning >}}
   **Never** run a **Development** mode server in a production environment. It is insecure and will lose data
   on every restart (since it stores data in-memory). It is only intended for development or experimentation.
   {{< /hint >}}

   <!-- spellchecker-disable -->
   {{< img name="oci-private-template-create-stack-config-lb-vault" size="large" lazy=false >}}
   <!-- spellchecker-enable -->

7. Fill in the following Database options. If you check `Show Database Options`, you can modify the following values:

   - `Autonomous Database Network Access` : Choose the Autonomous Database network access.
   - `Autonomous Database CPU Core Count` : The number of initial OCPUs used for the Oracle Autonomous Database Serverless (ADB-S) instance.
   - `Allow Autonomous Database OCPU Auto Scaling` : Turn on ADB-S auto scaling.
   - `Autonomous Database Data Storage Size` : The initial data storage size in terabytes (TB) for ADB-S.
   - `Autonomous Database License Model` : The Autonomous Database license model.

   <!-- spellchecker-disable -->
   {{< img name="oci-stack-db-options" size="large" lazy=false >}}
   <!-- spellchecker-enable -->

8. Now you can review the stack configuration and save the changes. Oracle recommends that you do not check the **Run apply** option. This
   gives you the opportunity to run the "plan" first and check for issues.

   <!-- spellchecker-disable -->
   {{< img name="oci-private-template-create-stack-config-review" size="large" lazy=false >}}
   <!-- spellchecker-enable -->

9. Apply the stack.

   After you create the stack, you can test the plan, edit the stack, and apply or destroy the stack.

   Oracle recommends that you test the plan before applying the stack in order to identify any issues before you start
   creating resources. Testing a plan does not create any actual resources. It is just an exercise to tell you what would
   happen if you did apply the stack.

   <!-- spellchecker-disable -->
   {{< img name="oci-stack-plan" size="large" lazy=false >}}
   <!-- spellchecker-enable -->

10. You can test the plan by clicking on **Plan** and reviewing the output. You can fix any issues (for example, you may find that
    you do not have enough quota for some resources) before proceeding.

    When you are happy with the results of the test, you can apply the stack by clicking on **Apply**. This creates your Oracle
	Backend as a Service (OBaas) for a Spring Cloud environment. This takes about 20 minutes to complete. Much of this time is spent
	provisioning the Kubernetes cluster, worker nodes, and database. You can watch the logs to follow the progress of the operation.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

11. The OCI Resource Manager applies your stack and generates the execution logs. The apply job takes approximately 45 minutes.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply-logs" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

12. Collect the OKE access information by clicking on **Outputs**.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-outputs" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

13. Click on **Copy** for the variable named `kubeconfig_cmd`. Save this information because it is needed to access the OKE cluster.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-output-oke" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## Set Up the Local Machine

To set up the local machine, process these steps:

1. Set up cluster access.

   To access a cluster, use the `kubectl` command-line interface that is installed (see the [Kubernetes access](./cluster-access)) locally.
   If you have not already done so, do the following:

2. Install the `kubectl` command-line interface (see the [kubectl documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/)).
	
3. Generate an API signing key pair. If you already have an API signing key pair, go to the next step. If not:

   a. Use OpenSSL commands to generate the key pair in the required P-Early-Media (PEM) format. If you are using Windows, you
	  need to install Git Bash for Windows in order to run the commands. See [How to Generate an API Signing Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two).

   b. Copy the contents of the public key to the clipboard to paste the value into the Console later.

4. Add the public key value of the API signing key pair to the **User Settings** for your user name. For example:
	
   a. In the upper right corner of the OCI Console, open the **Profile** menu (User menu symbol) and click **User Settings** to view the details.
	   
   b. Click **Add Public Key**.
	   
   c. Paste the value of the public key into the window and click **Add**.

      The key is uploaded and its fingerprint is displayed (for example, d1:b2:32:53:d3:5f:cf:68:2d:6f:8b:5f:77:8f:07:13).

5. Install and configure the Oracle Cloud Infrastructure CLI. For example:
	
   a. Install the Oracle Cloud Infrastructure CLI version 2.6.4 (or later). See [Quickstart](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#Quickstart).

   b. Configure the Oracle Cloud Infrastructure CLI. See [Configuring the CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Configuring_the_CLI).

6. Install the Oracle Backend for Spring Boot command-line.

   The Oracle Backend for Spring Boot command-line interface, `oractl`, is available for Linux and Mac systems. Download the binary
   that you want from the [Releases](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0) page and add it to
   your PATH environment variable. You can rename the binary to remove the suffix.

   If your environment is a Linux or Mac machine, run `chmod +x` on the downloaded binary. Also, if your environment is a Mac, run the
   following command. Otherwise, you get a security warning and the CLI does not work:
   
   `sudo xattr -r -d com.apple.quarantine <downloaded-file>`

Next, go to the [Azure/OCI Multicloud Installation](../azure/) page to learn how to install Multicloud.
