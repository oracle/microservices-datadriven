
The MBaaS is available to install from [OCI Marketplace](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/139274906).

## Prerequisites

You must meet the following prerequisites to use the MBaaS:

* An OCI account in a tenancy with sufficient quota to create:
  * An OCI Container Engine for Kubernetes cluster, plus a node pool with three worker nodes
  * A VCN with at least two public IP's available
  * A public load balancer
  * An Oracle Autonomous Database - Shared instance
  * At least one free OCI Auth Token (note that the maximum is two per user)

## Setup

To start installation:

* Visit the [OCI Marketplace listing for MBaaS](https://cloud.oracle.com/marketplace/application/139274906) (see the image below)
* Log into OCI Console if requested
* Choose the target compartment
* Review and accept the terms and conditions
* Click on the "Launch Stack" button

![OCI Marketplace Listing](../mbaas-oci-mp-listing.png)

On the "Create Stack" page:

* Modify the suggested name if desired
* Add a description or tags if desired
* Click on the "Next" button

On the "Configure variables" page, in the "Backend as a Service" section (see image below):

* Set an application name if desired, if you do not, a randomized value will be generated.  This will be the name of the Parse application
* Set an application ID if desired, if you do not, a randomized value will be generated.  This will be the Parse APPLICATION_ID
* Set a server master key if desired, if you do not, a randomized value will be generated.  This will the Parse MASTER_KEY
* Change the dashboard user name if desired, note that this is case-sensitive
* Provide a password for the dashboard user.  Oracle recommends that you use a strong password

![Configure variables page](../mbaas-configure-variables.png)

In the "Control Plane Options" section, modify the CIDR if desired.  Note that you will only be able to access the service from IP
addresses in the specified CIDR.

In the "Node Pool" section you can customize the number of nodes and enable auto-scaling if desired.

In the "Load Balancers Options" section you can customize the load balancer shape and the CIDR for client access.  For simple testing, Oracle
recommends using the provided default values.

In the "Database Options" section you can customize the database shape and the CIDR for client access. Note that you will not be able to access
Datbase Actions if you change the network access to "PRIVATE_ENDPOINT_ACCESS"

Once you have completed customization, click on the "Next" button. 

The "Review" page is displayed, check your settings and then click on the "Create" button to create the "stack" and run the Terraform apply
action to create all of the associated resources.  

You can monitor the installation in the log. Installation takes approximately 20 minutes to complete.  Most of this time is spent provisioning
the Kubernetes cluster, its nodes, and the database.

When the installation is finished, some important information will be included at the end of the log.  You will need this information to access
the newly created environment:

```
application_id = "COOLAPPV100"
dashboard_password = <sensitive>
dashboard_uri = "http://1.2.3.4"
dashboard_user = "ADMIN"
kubeconfig_cmd = "oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.iad.xxx
 --file $HOME/.kube/config --region us-ashburn-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
parse_endpoint = "1.2.3.4/parse"
```

Next, move on the the [Getting Started](../getting-started/) page to learn how to use the newly installed environment.