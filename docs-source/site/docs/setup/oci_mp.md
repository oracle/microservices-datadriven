---
title: OCI Marketplace Installation
sidebar_position: 1
---
## Overview

This Document describes how to install Oracle Backend for Microservices and AI (OBaaS) from OCI Marketplace.

### Prerequisites

- Access to an OCI Tenancy
- Quota to create and Oracle Backend for Microservices and AI
  - An OCI Container Engine for Kubernetes cluster (OKE cluster), plus a node pool with three worker nodes.
    - Each node should have 2 OCPUs and 32 GB of RAM.
    - 750GB of block volume storage with a `Balanced` performance level.

  - A virtual cloud network (VCN) with at least two public IP's available.
  - A public load balancer.
  - An Oracle Autonomous Database Serverless instance.
    - The instance should have 2 ECPUs and 20GB storage and 20GB backup storage.

- The right [OCI policies →](./oci_policies.md) in place.

### Overview of setup process

Installing Oracle Backend for Microservices and AI and Microservice takes approximately 30-45 minutes. The following steps are involved:

- [Setup the OCI environment](#setup-the-oci-environment)
- [Access environment variables from the OCI Console](#access-environment-variables-from-the-oci-console)

#### Setup the OCI environment

To set up the OCI environment, process these steps:

1. Go to the [OCI Marketplace listing for Oracle Backend for Microservices and AI](https://cloud.oracle.com/marketplace/application/138899911).

    IMAGE

    Choose the target compartment, agree to the terms, and click **Launch Stack**.  This starts the wizard and creates the new stack. On the first page, choose a compartment to host your stack and select **Next** and Configure the variables for the infrastructure resources that this stack will create when you run the apply job for this execution plan.

    IMAGE

1. In the **Backend as A Service** Section, fill in the following configuration variables as needed and select **Next**:

    - `Compartment` : Select the compartment where you want to install Oracle Backend for Microservices and AI.
    - `Application Name` (optional) : A random pet name that will be used as the application name if left empty.
    - `Edition` : Select between *COMMUNITY* and *STANDARD* Edition.
      - *COMMUNITY* - for developers for quick start to testing Spring Boot Microservices with an integrated backend. Teams can start with the deployment and scale up as processing demand grows. Community support only.
      - *STANDARD* - focused for pre-prod and production environments with an emphasis on deployment, scaling, and high availability. Oracle support is included with a Oracle Database support agreement. All features for developers are the same so start here if you’re porting an existing Spring Boot application stack and expect to get into production soon.  This edition allows for additional Bring Your Own (BYO) capabilities.


#### Access environment variables from the OCI Console

You can get the necessary access information from the OCI COnsole:

- OKE Cluster Access information e.g. how to generate the kubeconfig information.
- Oracle Backend for Microservices and AI Passwords.

The assigned passwords (either auto generated or provided by the installer) can be viewed in the OCI Console (ORM homepage). Click on Application Information in the OCI ORM Stack.

IMAGE

You will presented with a screen with the access information and passwords. NOTE: The passwords can also be accessed from the k8s secrets.

IMAGE

Add to documentation, can happen! Rerun Apply job

```log
module.kubernetes["managed"].oci_identity_policy.workers_policies: Creating...
module.kubernetes["managed"].oci_identity_policy.workers_policies: Creation complete after 0s [id=ocid1.policy.oc1..aaaaaaaasaxvpssa2h2qgzacgc5az6s477gn3o4sdhwwh3fo7jxyxmu2k24a]
╷
│ Error: During creation, Terraform expected the resource to reach state(s): ACTIVE,NEEDS_ATTENTION, but the service reported unexpected state: DELETING.
│ 
│   with module.kubernetes["managed"].oci_containerengine_addon.ingress_addon[0],
│   on modules/kubernetes/main.tf line 125, in resource "oci_containerengine_addon" "ingress_addon":
│  125: resource "oci_containerengine_addon" "ingress_addon" {
│ 
```