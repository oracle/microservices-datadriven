---
title: Azure/OCI Multi-Cloud Installation
---

The Oracle Backend for Spring Boot is available to install in Multi-Cloud (Azure and Oracle Cloud Infrastructure (OCI)).  This installation deplpoys the Oracle Backend for Spring Boot in Azure with an Oracle Autonomous Database running in OCI.

## Prerequisites

You must meet the following prerequisites to use the Oracle Backend for Spring Boot Multi-Cloud (Azure and OCI). You need:

* An account on Azure
* An account on OCI

## Overview of setup process

This video provides a quick overview of the setup process.

{{< youtube IpWe12UYeJ4 >}}

## Download

Download [Oracle Backend for Spring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/azure-ebaas_latest.zip).

## Setup

A few setup steps are required in both Oracle Cloud Infrastructure (OCI) and Azure to deploy the Oracle Backend for Spring Boot application.

### OCI

The Multi-Cloud installation provisions an Oracle Autonomous Database in OCI using the [Oracle Database Operator for Kubernetes (OraOperator)](https://github.com/oracle/oracle-database-operator).  

To allow the OraOperator access to OCI, an [API Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm) must be generated using these steps:

1. Log into OCI.
2. Open the **Profile** menu ![User Profile Menu](userprofilemenu.png) and click **User** settings.
3. In the **Resources** section at the bottom left, click **API Keys**.
4. Click **Download Private Key** and save the key as `private_key.pem`. You do not need to download the public key.
5. Click **Add**.

The key is added and the Configuration File Preview is displayed. The file snippet includes the required parameters and values. Copy and paste the configuration file snippet from the text box and save for later steps.

### Azure

The Multi-Cloud installation is done using the Azure Cloud Shell.  The following steps are required in Azure to prepare for the installation:

1. Log into Azure.

2. Open the Azure Cloud Shell. For example:

   ![Azure Cloud Shell Icon](AzureCloudShellIcon.png)
   
3. Upload the [Oracle Backend for Spring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/azure-ebaas-platform_latest.zip) Stack

   ![Azure Upload](AzureUpload.png)
   
4. Upload the API Private Key (`private_key.pem`).

5. Unzip the Stack to a directory called OBaaS. For example:

   `unzip azure-ebaas-platform_latest.zip -d /tmp/obaas`
	
6. Move the `private_key.pem` file to OBaaS. For example:

   `mv private_key.pem /tmp/obaas/`
   
7. Run the configuration helper script, using the values from the API Key. For example:

   `cd /tmp/obaas`
   `./obaas_configure.py`
   ![Azure Configure](AzureConfigure.png)


## Install Ansible

Install Ansible to run the Configuration Management Playbook.  The helper script creates a Python virtual environment and installs Ansible and additional modules. For example:

```bash
cd /tmp/obaas/ansible
./setup_ansible.sh
source ./activate.env
```

## Deploy the Infrastructure

From the Azure Cloud Shell, run these commands:

```bash
cd /tmp/obaas
terraform init
terraform plan -out=multicloud.plan
terraform apply "multicloud.plan"
```

## Finish

Next, go to the [Getting Started](../getting-started/) page to learn how to use the newly installed environment.
