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
    title: "Compartment, Application and Editon"
  - name: ebaas-mp-listing
    src: "ebaas-mp-listing.png"
    title: "Marketplace Listing"
  - name: ebaas-stack-page1
    src: "ebaas-stack-page1.png"
    title: "Create Stack"
  - name: oci-stack-passwords
    src: "oci-stack-passwords.png"
    title: "Administrator Passwords"
  - name: oci-stack-control-plane
    src: "oci-stack-control-plane.png"
    title: "OKE Control Plane Access"
  - name: oci-stack-node-pool
    src: "oci-stack-node-pool.png"
    title: "Node Pool Information"
  - name: oci-stack-lb-options
    src: "oci-stack-lb-options.png"
    title: "Load Balancer Options"
  - name: oci-stack-vault-options
    src: "oci-stack-vault-options.png"
    title: "HashiCorp Vault Options"
  - name: azn-stack-app-info
    src: "azn-stack-app-info.png"
    title: "Access Information"
  - name: oci-stack-app-info
    src: "oci-stack-app-information.png"
    title: "Detailed Access Information"
---

Oracle Backend for Spring Boot and Microservices is available in the [OCI Marketplace](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/138899911).

## Prerequisites

You must meet the following prerequisites to use Oracle Backend for Spring Boot and Microservices. You need:

- An Oracle Cloud Infrastructure (OCI) account in a tenancy with sufficient quota to create the following:

  - An OCI Container Engine for Kubernetes cluster (OKE cluster), plus a node pool with three worker nodes.
  - A virtual cloud network (VCN) with at least two public IP's available.
  - A public load balancer.
  - An Oracle Autonomous Database Serverless instance.
  
- At least one free OCI auth token (note that the maximum is two per user).

- On a local machine, you need:

  - The Kubernetes command-line interface (kubectl). [Installing kubectl documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
  - Oracle Cloud Infrastructure command-line interface (CLI). [Quickstart - Installing the CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#Quickstart).
  - Oracle Backend for Spring Boot and Microservices command-line interface (oractl). [oractl Downloads](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0).

## Summary of Components

Oracle Backend for Spring Boot and Microservices setup installs the following components:

| Component                    | Version       | Description                                                                                 |
|------------------------------|---------------|---------------------------------------------------------------------------------------------|
| cert-manager                 | 1.12.3        | Automates the management of certificates.                                                   |
| NGINX Ingress Controller     | 1.8.1         | Provides traffic management solution for cloud‑native applications in Kubernetes.           |
| Prometheus                   | 2.40.2        | Provides event monitoring and alerts.                                                       |
| Prometheus Operator          | 0.63.0        | Provides management for Prometheus monitoring tools.                                        |
| OpenTelemetry Collector      | 0.86.0        | Collects process and export telemetry data.                                                 |
| Grafana                      | 9.2.5         | Provides the tool to examine, analyze, and monitor metrics.                                 |
| Jaeger Tracing               | 1.45.0        | Provides distributed tracing system for monitoring and troubleshooting distributed systems. |
| Apache APISIX                | 3.4.0         | Provides full lifecycle API management.                                                     |
| Spring Boot Admin server     | 3.1.3         | Manages and monitors Spring Cloud applications.                                             |
| Spring Cloud Config server   | 2022.0.4      | Provides server-side support for an externalized configuration.                             |
| Spring Eureka service registry | 2022.0.4 (4.0.3)      | Provides service discovery capabilities.                                                    |
| HashiCorp Vault              | 1.14.0        | Provides a way to store and tightly control access to sensitive data.                       |
| Oracle Database Operator     | 1.0           | Helps reduce the time and complexity of deploying and managing Oracle databases.            |
| Oracle Transaction Manager for Microservices | 22.3.2 | Manages distributed transactions to ensure consistency across Microservices.       |
| Strimzi-Apache Kafka operator  | 0.36.1      | Manages Apache Kafka clusters.                                                              |
| Apacha Kafka                 | 3.4.0 - 3.5.1 | Provides distributed event streaming.                                                       |
| Coherence                    | 3.2.11        | Provides in-memory data grid.                                                               |
| Parse Server (optional)      | 6.3.0         | Provides backend services for mobile and web applications.                                  |
| Parse Dashboard (optional)   | 5.2.0         | Provides web user interface for managing the Parse Server.                                  |
| Oracle Database storage adapter for Parse  (optional) | 1.0.0    | Enables the Parse Server to store data in Oracle Database.              |
| Conductor Server             | 3.13.2        | Provides a Microservice orchestration platform.                                             |
| Loki                         | 2.6.1     | Provides log aggregation and search. |
| Promtail                     | 2.8.2     | Collects logs.                       |
| Spring Authorization Server  | 2022.0.4  | Provides authentication and authorization for applications. |

## Overview of the Setup Process

This video provides a quick overview of the setup process.

{{< youtube rAi10TiUraE >}}

Installing Oracle Backend for Spring Boot and Microservice takes approximately one hour to complete. The following steps are involved:

- [Setup the OCI environment](#set-up-the-oci-environment)
- [Setup of the Local Eenvironment](#set-up-the-local-machine)
- [Access environment variables from the OCI Console](#access-information-and-passwords-from-the-oci-console)

## Set Up the OCI Environment

To set up the OCI environment, process these steps:

1. Go to the [OCI Marketplace listing for Oracle Backend for Spring Boot and Microservices](https://cloud.oracle.com/marketplace/application/138899911).

    <!-- spellchecker-disable -->
    {{< img name="ebaas-mp-listing" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

    Choose the target compartment, agree to the terms, and click **Launch Stack**.  This starts the wizard and creates the new stack. On the first page, choose a compartment to host your stack and select **Next** and Configure the variables for the infrastructure resources that this stack will create when you run the apply job for this execution plan.

    <!-- spellchecker-disable -->
    {{< img name="ebaas-stack-page1" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. In the **Backend as A Service** Section, fill in the following configuration variables as needed and select **Next**:

    - `Compartment` : Select the compartment where you want to install Oracle Backend for Spring Boot and Microservices.
    - `Application Name` (optional) : A random pet name that will be used as the application name if left empty.
    - `Edition` : Select between *COMMUNITY* and *STANDARD* Edition.
        - *COMMUNTIY* - for developers for quick start to testing Spring Boot Microservices with an integrated backend. Teams can start with the deployment and scale up as processing demand grows. Community support only.
        - *STANDARD* - focused for pre-prod and production environments with an emphasis on deployment, scaling, and high availability. Oracle support is included with a Oracle Database support agreement. All features for developers are the same so start here if you’re porting an existing Spring Boot application stack and expect to get into production soon.

      <!-- spellchecker-disable -->
      {{< img name="oci-stack-app-name" size="large" lazy=false >}}
      <!-- spellchecker-enable -->

1. If you check the checkbox *Set Administrator Passwords* in the **Administrator Passwords** section you have the option to fill in the following passwords (if not they are autogenerated):

   - `APISIX Administrator Password` (optional) : Leave blank to auto-generate.
   - `Grafana Administrator Password` (optional) : Leave blank to auto-generate.
   - `ORACTL Administrator Password` optional) : Leave blank to auto-generate. This is the password for the `obaas-admin` user.
   - `ORACTL User Password` (optional) : Leave blank to aout-generate. This is the password for the `obaas-user` user.

      <!-- spellchecker-disable -->
      {{< img name="oci-stack-passwords" size="large" lazy=false >}}
      <!-- spellchecker-enable -->

1. If you check the checkbox *Enable Parse Platform* in the **Parse Server** section a Parse Server will be installed. Fill in the following for the Parse Server:

   - `Application ID` (optional) : Leave blank to auto-generate.
   - `Server Master Key` (optional) : Leave blank to auto-generate.
   - `Enable Parse S3 Storage` : Check the checkbox to enable Parse Server S3 Adaptor and create a S3 compatible Object Storage Bucket.
   - `Dashboard Username` : The user name of the user to whom access to the dashboard is granted.
   - `Dashboard Password` (optinal) : The password of the dashboard user (a minimum of 12 characters). Leave blank to aout-generate.

     <!-- spellchecker-disable -->
     {{< img name="oci-stack-parse-options" size="large" lazy=false >}}
     <!-- spellchecker-enable -->

1. If you check the checkbox *Public Control Plane* in the **Public Control Plane Options**, you are enabling access from the `public` to the Control Plane:
  
   - `Public Control Plane` : This option allows access to the OKE Control Plane from the internet (public IP). If not selected, access can only be from a private virtual cloud network (VCN).
   - `Control Plane Access Control` : Enter the CIDR block you want to give access to the Control Plane. Default (and not recommended) is `0.0.0.0/0`.

   > **NOTE:** Oracle recommends that you set `Control Plane Access Control` to be as restrictive as possible

     <!-- spellchecker-disable -->
     {{< img name="oci-stack-control-plane" size="large" lazy=false >}}
     <!-- spellchecker-enable -->

1. In the **Node Pool** section, fill in the following for the OKE Node Pools:

   - `Node Pool Workers` : The number of Kubernetes worker nodes (virtual machines) attached to the OKE cluster.
   - `Node Pool Worker Shape` : The shape of the node pool workers.
   - `Node Workers OCPU` : The initial number of Oracle Compute Units (OCPUs) for the node pool workers.

      <!-- spellchecker-disable -->
      {{< img name="oci-stack-node-pool" size="large" lazy=false >}}
      <!-- spellchecker-enable -->

1. In the **Load Balanacers Options** section, fill in the following for the Load Balancers options:

   - `Enable Public Load Balancer` : This option allows access to the load balancer from the internet (public IP). If not
      selected, access can only be from a private VCN.
   - `Public Load Balancer Access Control` : Enter the CIDR block you want to give access to the Load Blanacer. Default (and not recommended) is `0.0.0.0/0`.
   - `Public Load Balancer Ports Exposed` : The ports exposed from the load balancer.
   - `Minimum bandwidth` : The minimum bandwidth that the load balancer can achieve.
   - `Maximum bandwidth` : The maximum bandwidth that the load balancer can achieve.

   > **NOTE:** Oracle recommends that you set `Public Load Balancer Access Control` to be as restrictive as possible.

      <!-- spellchecker-disable -->
      {{< img name="oci-stack-lb-options" size="large" lazy=false >}}
      <!-- spellchecker-enable -->

1. If you check the checkbox *Enable Vault in Production Mode* in the section **Vault Options** you will be installing HashiCorp in **Production** mode otherwise the HashiCorp Vault be installed in **Developement** mode.

    Fill in the following Vault options. You have the option of creating a new OCI Vault or using an existing OCI Vault. The OCI Vault is only used in **Production** mode to auto-unseal the HashiCorp Vault (see documentation ...) Fill in the following information if you want to use an existing OCI Vault:

   - `Vault Compartment (Optional)` : Select a compartment for the OCI Vault.
   - `Existing Vault (Optional)` : Select an existing OCI Vault. If not selected a new OCI Vault be created.
   - `Existing Vault Key (Optional)` : Select an existing OCI Vault key. If not selected a new OCI Vault Key will be created.

      <!-- spellchecker-disable -->
      {{< img name="oci-stack-vault-options" size="large" lazy=false >}}
      <!-- spellchecker-enable -->

   {{< hint type=[warning] icon=gdoc_check title=Warning >}}
   **Never** run a **Development** mode HashiCorp Vault Server in a production environment. It is insecure and will lose data on every restart (since it stores data in-memory). It is only intended for development or experimentation.
   {{< /hint >}}

1. In the **Database Options** section, you can modify the following Database options.

   - `Autonomous Database Network Access` : Choose the Autonomous Database network access. Choose between *SECURE_ACCESS* and *PRIVATE_ENDPOINT_ACCESS*. **NOTE:** This option currently cannot be changed later.
      - *SECURE_ACCESS* - Accessible from outside the Kubernetes Cluster.  Requires mTLS and can be restricted by IP or CIDR addresses.
      - *PRIVATE_ENDPOINT* - Accessible only from inside the Kubernetes Cluster or via a Bastion service.  Requires mTLS.
   - `ADB Access Control` : Comma separated list of CIDR blocks from which the ADB can be accessed. This only applies if *SECURE_ACCESS* was choosen. Default (and not recommended) is `0.0.0.0/0`.
   - `Autonomous Database ECPU Core Count` : Choose how many ECPU cores will be elastically allocated.
   - `Allow Autonomous Database OCPU Auto Scaling` : Enable auto scaling for the ADB ECPU core count (x3 ADB ECPU).
   - `Autonomous Database Data Storage Size` : Choose ADB Database Data Storage Size in gigabytes.
   - `Autonomous Database License Model` : The Autonomous Database license model.

    > **NOTE:** Oracle recommends that you restrict by IP or CIDR addresses to be as restrictive as possible.

      <!-- spellchecker-disable -->
      {{< img name="oci-stack-db-options" size="large" lazy=false >}}
      <!-- spellchecker-enable -->

1. Now you can review the stack configuration and save the changes. Oracle recommends that you do not check the **Run apply** option. This gives you the opportunity to run the "plan" first and check for issues. Click **Create**

   <!-- spellchecker-disable -->
   {{< img name="oci-private-template-create-stack-config-review" size="large" lazy=false >}}
   <!-- spellchecker-enable -->

1. Apply the stack.

   After you create the stack, you can test the plan, edit the stack, and apply or destroy the stack.

   Oracle recommends that you test the plan before applying the stack in order to identify any issues before you start
   creating resources. Testing a plan does not create any actual resources. It is just an exercise to tell you what would
   happen if you did apply the stack.

   You can test the plan by clicking on **Plan** and reviewing the output. You can fix any issues (for example, you may find that you do not have enough quota for some resources) before proceeding.

   <!-- spellchecker-disable -->
   {{< img name="oci-stack-plan" size="large" lazy=false >}}
   <!-- spellchecker-enable -->

1. When you are happy with the results of the test, you can apply the stack by clicking on **Apply**. This creates your Oracle Backend as a Service and Microservices for a Spring Cloud environment. This takes about 20 minutes to complete. Much of this time is spent provisioning the Kubernetes cluster, worker nodes, database and all the included services. You can watch the logs to follow the progress of the operation.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. The OCI Resource Manager applies your stack and generates the execution logs. The apply job takes approximately 45 minutes.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-apply-logs" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. When the **Apply** job finsishes you can collect the OKE access information by clicking on **Outputs**.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-outputs" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

1. Click on **Copy** for the variable named `kubeconfig_cmd`. Save this information because it is needed to access the OKE cluster.

    <!-- spellchecker-disable -->
    {{< img name="oci-stack-output-oke" size="large" lazy=false >}}
    <!-- spellchecker-enable -->

## Set Up the Local Machine

To set up the local machine, process these steps:

1. Set up cluster access.

   To access a cluster, use the `kubectl` command-line interface that is installed (see the [Kubernetes access](./cluster-access)) locally.
   If you have not already done so, do the following:

1. Install the `kubectl` command-line interface (see the [kubectl documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/)).

1. Generate an API signing key pair. If you already have an API signing key pair, go to the next step. If not:

   a. Use OpenSSL commands to generate the key pair in the required P-Early-Media (PEM) format. If you are using Windows, you need to install Git Bash for Windows in order to run the commands. See [How to Generate an API Signing Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two).

   b. Copy the contents of the public key to the clipboard to paste the value into the Console later.

1. Add the public key value of the API signing key pair to the **User Settings** for your user name. For example:

   a. In the upper right corner of the OCI Console, open the **Profile** menu (User menu symbol) and click **User Settings** to view the details.

   b. Click **Add Public Key**.

   c. Paste the value of the public key into the window and click **Add**.

      The key is uploaded and its fingerprint is displayed (for example, d1:b2:32:53:d3:5f:cf:68:2d:6f:8b:5f:77:8f:07:13).

1. Install and configure the Oracle Cloud Infrastructure CLI. For example:

   a. Install the Oracle Cloud Infrastructure CLI version 2.6.4 (or later). See [Quickstart](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#Quickstart).

   b. Configure the Oracle Cloud Infrastructure CLI. See [Configuring the CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm#Configuring_the_CLI).

1. Install the Oracle Backend for Spring Boot and Microservices command-line.

   The Oracle Backend for Spring Boot and Microservices command-line interface, `oractl`, is available for Linux and Mac systems. Download the binary that you want from the [Releases](https://github.com/oracle/microservices-datadriven/releases/tag/OBAAS-1.0.0) page and add it to your PATH environment variable. You can rename the binary to remove the suffix.

   If your environment is a Linux or Mac machine, run `chmod +x` on the downloaded binary. Also, if your environment is a Mac, run the following command. Otherwise, you get a security warning and the CLI does not work:

   `sudo xattr -r -d com.apple.quarantine <downloaded-file>`

## Access information and passwords from the OCI Console

You can get the necessary access information from the OCI COnsole:

- OKE Cluster Access information e.g. how to generate the kubeconfig information.
- Oracle Backend for Spring Boot and Microservices Passwords.

The assigned passwords (either auto generated or provided by the installer) can be viewed in the OCI Console (ORM homepage). Click on Application Information in the OCI ORM Stack.

<!-- spellchecker-disable -->
{{< img name="azn-stack-app-info" size="large" lazy=false >}}
<!-- spellchecker-enable -->

You will presented with a screen with the access information and passwords. **NOTE**: The passwords can also be accessed from the k8s secrets.

<!-- spellchecker-disable -->
{{< img name="oci-stack-app-info" size="large" lazy=false >}}
<!-- spellchecker-enable -->
