---
title: "Setup"
---

The Oracle Backend for Parse Platform is available to install from [OCI Marketplace](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/139274906).

## Prerequisites

You must meet the following prerequisites to use the Oracle Backend for Parse Platform. You need:

* An Oracle Cloud Infrastructure (OCI) account in a tenancy with sufficient quota to create the following:

  * An OCI Container Engine for Kubernetes cluster (OKE cluster), plus a node pool with three worker nodes.
  * A Virtual Cloud Network (VCN) with at least two public IP's available.
  * A public load balancer.
  * An Oracle Autonomous Database Serverless instance.

* At least one free OCI auth token (note that the maximum is two per user).

## Setup

To start the installation, take the following steps:

1. Visit the [OCI Marketplace listing for Oracle Backend for Parse Platform](https://cloud.oracle.com/marketplace/application/139274906) (see the following image).
2. Log in to the OCI Console, if requested.
3. Choose the target compartment.
4. Review and accept the terms and conditions.
5. Click **Launch Stack**.

   ![OCI Marketplace Listing](../mbaas-oci-mp-listing.png)

6. On the **Create Stack** page:

   a. Modify the suggested name, if desired.
   
   b. Add a description or tags, if desired.
   
   c. Click **Next**.

7. On the **Configure variables** page, in the **Backend as a Service** section (see the following image):

   a. Specify an application name, if desired. If not specified, a randomized value is generated.  This is the name of the Parse application.
   
   b. Specify an application ID, if desired. If not specified, a randomized value is generated.  This is the Parse `APPLICATION_ID`.
   
   c. Specify a server master key, if desired. If not specified, a randomized value is generated.  This is the Parse `MASTER_KEY`.
   
   d. Change the dashboard user name, if desired. Note that this is case-sensitive.
   
   e. Provide a dashboard password for the dashboard user. Oracle recommends using a strong password for security purposes.
   
   For example:

   ![Configure variables page](../mbaas-configure-variables.png)

8. In the **Control Plane Options** section, modify the Classless Inter-Domain Routing (CIDR) block, if desired. Note that you can only access the service from IP
   addresses in the specified CIDR block.

9. In the **Node Pool** section, you can customize the number of nodes and enable auto scaling, if desired.

10. In the **Load Balancers Options** section, you can customize the load balancer shape and the CIDR for client access. For simple testing, Oracle
    recommends using the default values.

11. In the **Database Options** section, you can customize the database shape and the CIDR for client access. Note that you cannot access
    **Database Actions** if you change the network access to `PRIVATE_ENDPOINT_ACCESS`.

12. Once you have completed customization, click **Next**. 

13. The **Review** page is displayed. Check your settings and then click **Create** to create the stack and run the Terraform `apply`
    command to create all of the associated resources.  

You can monitor the installation in the log. Installation takes approximately 20 minutes to complete.  Most of this time is spent provisioning
the Kubernetes cluster, its nodes, and the database.

When the installation is finished, some important information is included at the end of the log.  You need this information to access
the newly created environment. For example:

```
application_id = "COOLAPPV100"
dashboard_password = <sensitive>
dashboard_uri = "http://1.2.3.4"
dashboard_user = "ADMIN"
kubeconfig_cmd = "oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.iad.xxx
 --file $HOME/.kube/config --region us-ashburn-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
parse_endpoint = "1.2.3.4/parse"
```

Next, go to the [Microsoft Azure/OCI Multicloud Installation](../azure/) page to learn how to use the newly installed environment.