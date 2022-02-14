# Jenkins Micro Deployment on OCI

This terraform configuration deploys a minimal Jenkins CI/CD server on Oracle Cloud Infrastructure. It provides a way to get started with Jenkins quickly and scale out the deployment when required. 

The deployment creates a minimal footprint and uses a single compute instance and runs Jenkins within a docker container. The installation can be scaled to meet larger workloads and continuous builds by scaling this deployment, installaing the Oracle Cloud Infrastructure Plugin that can create compute instances on demand to meet the Jenkins workload or by deploying Jenkins on to an OKE cluster to let Kubernetes manage the Jenkins build agents.

## Prerequisites

- Permission to `manage` the following types of resources in your Oracle Cloud Infrastructure tenancy: `vcns`, `internet-gateways`, `route-tables`, `security-lists`, `subnets` and `instances`.

- Quota to create the following resources: 1 VCN, 1 subnet, 1 Internet Gateway, and 1 compute instance (Jenkins CMS).

If you don't have the required permissions and quota, contact your tenancy administrator. See [Policy Reference](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm), [Service Limits](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/servicelimits.htm), [Compartment Quotas](https://docs.cloud.oracle.com/iaas/Content/General/Concepts/resourcequotas.htm).

## Deploy Using Oracle Resource Manager

To deploy this solution using Oracle Resource Manager, click on the deployment button below to start the deployment in your oracle cloud infrastructure tenancy.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-arch-jenkins/releases/download/v1.1/oci-arch-jenkins-stack-micro-latest.zip)

Alternatively, you can download the stack for this solution from the **Releases** a section of this repository. Navigate to Oracle resource manager in the Oracle Cloud Infrastructure console. Here import the zip file as a new resource manager stack.You can now perform terraform actions like plan or apply.

The stack exposes several variables that can be configured. By default the stack only prompts the user for the administrative password for Jenkins. Users can choose to use the advanced options to provide further configuration of the stack.

## Deploy Using the Terraform CLI

### Clone the Module

Now, you'll want a local copy of this repo. You can make that with the commands:

```
    git clone https://github.com/oracle-quickstart/oci-arch-theia-mds.git
    cd oci-arch-theia-mds
    ls
```

### Prerequisites
First off, you'll need to do some pre-deploy setup.  That's all detailed [here](https://github.com/cloud-partners/oci-prerequisites).

Create a `terraform.tfvars` file, and specify the following variables:

```
# Authentication
tenancy_ocid         = "<tenancy_ocid>"
user_ocid            = "<user_ocid>"
fingerprint          = "<finger_print>"
private_key_path     = "<pem_private_key_path>"

# Region
region = "<oci_region>"

# Availablity Domain 
availablity_domain_name = "<availablity_domain_name>"

````

### Create the Resources
Run the following commands:

    terraform init
    terraform plan
    terraform apply


### Testing your Deployment
After the deployment is finished, you can access WP-Admin by picking theia_wp-admin_url output and pasting into web browser window. You can also verify initial content of your blog by using jenkins_public_ip:

````
theia_wp-admin_url = http://193.122.198.19/wp-admin/
jenkins_public_ip = 193.122.198.19
`````

### Destroy the Deployment
When you no longer need the deployment, you can run this command to destroy the resources:

    terraform destroy

## Architecture Diagram

![](./images/architecture-deploy-theia-mds.png)


