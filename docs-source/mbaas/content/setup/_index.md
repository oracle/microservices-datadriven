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

When the installation is finished, some important information is included at the end of the log. You need this information to access
the newly created environment. For example:

```text
kubeconfig_cmd = "oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.iad.aaaaaaaatc --region us --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT --file $HOME/.kube/config"
parse_application_id = "MYCOOLAPP001"
parse_dashboard_password = <sensitive>
parse_dashboard_uri = "https://1.2.3.4/parse-dashboard"
parse_dashboard_user = "ADMIN"
parse_endpoint = "https://1.2.3.4/parse"
parse_master_key = <sensitive>
```

## TLS

The Oracle Backend for Parse Platform is deployed with a sample self-signed certificate for Transport Layer Security (TLS). This results in an "Accept Risk" message when accessing the Parse Dashboard and the sample TLS certificate should not be used for production deployments.

### Updating the TLS Certificate

1. Ensure your Domain Name System (DNS) entry points to the IP address specified in the `parse_dashboard_uri` output.
2. Obtain a new TLS certificate. In a production environment, the most common scenario is to use a public certificate that has been signed by a certificate authority.
3. Create a new Kubernetes secret in the `ingress-nginx` namespace.  For example:

    ```bash
    kubectl -n ingress-nginx create secret tls my-tls-cert --key new-tls.key --cert new-tls.crt
    ```

4. Modify the service definition to reference the new Kubernetes secret by changing the `service.beta.kubernetes.io/oci-load-balancer-tls-secret` annotation in the service configuration. For example:

    ```bash
    kubectl patch service ingress-nginx-controller -n ingress-nginx \
        -p '{"metadata":{"annotations":{"service.beta.kubernetes.io/oci-load-balancer-tls-secret":"my-tls-cert"}}}' \
        --type=merge
    ```

Next, go to the [Microsoft Azure/OCI Multicloud Installation](../azure/) page to learn how to use the newly installed environment.