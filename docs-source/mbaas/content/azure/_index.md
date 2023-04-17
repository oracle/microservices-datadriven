# Azure/OCI Multi-Cloud Installation

The Oracle Backend for Parse Platform is available to install in Multi-Cloud (Azure and OCI).  This installation will deplpoy the Oracle Backend for Parse Platform in Azure with an Oracle Autonomous Database running in OCI.

## Prerequisites

You must meet the following prerequisites to use the Oracle Backend for Spring Boot Multi-Cloud (Azure and OCI):

* An account on Azure
* An account on OCI

## Download

Download [Oracle Backend for Spring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/azure-mbaas-platform_latest.zip).

## Setup

A few setup steps are required in both Oracle Cloud Infrastructure (OCI) and Azure to deploy the Oracle Backend for Parse Platform application.

### OCI

The Multi-Cloud Installation will provision an Oracle Autonomous Database in OCI via the [Oracle Database Operator for Kubernetes (OraOperator)](https://github.com/oracle/oracle-database-operator).  

To allow the OraOperator access to OCI, an [API Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm) must be generated:

1. Log into OCI
2. Open the Profile menu ![User Profile Menu](userprofilemenu.png) and click My profile.
3. In the Resources section at the bottom left, click API Keys
4. Click Download Private Key and save the key as `private_key.pem`. You do not need to download the public key.
5. Click Add.

The key is added and the Configuration File Preview is displayed. The file snippet includes required parameters and values you'll need. Copy and paste the configuration file snippet from the text box and keep handy for later steps.

### Azure

The Multi-Cloud Installation will be done via the Azure Cloud Shell.  The following steps are required in Azure to prepare for the installation.

1. Log into Azure
2. Open the Azure Cloud Shell
    ![Azure Cloud Shell Icon](AzureCloudShellIcon.png)
3. Upload the [Oracle Backend for Spring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/azure-ebaas-platform_latest.zip) Stack
    ![Azure Upload](AzureUpload.png)
4. Upload the API Private Key (`private_key.pem`)
5. Unzip the Stack to a directory called `obaas`
    `unzip azure-ebaas-platform_latest.zip -d obaas`
6. Move the `private_key.pem` file to obaas
    `mv private_key.pem obaas/`
5. Run the configuration helper script, inputing the values from the API Key
    * `cd ~/obaas`
    * `./obaas_configure.py`
    ![Azure Configure](AzureConfigure.png)

## Install Ansible

Install Ansible to run the Configuration Management Playbook.  The helper scripts will create a Python Virtual Environment and install Ansible and additional modules:

```bash
cd ~/obaas/ansible
./setup_ansible.sh
source ./activate.env
```

## Deploy the Infrastructure

From the Azure Cloud Shell:

```bash
cd ~/obaas
terraform init
terraform plan -out=multicloud.plan
terraform apply "multicloud.plan"
```

## Finish

Next, move on the the [Getting Started](../getting-started/) page to learn how to use the newly installed environment.