+++
archetype = "page"
title = "Introduction"
weight = 1
+++

This module walks you through the steps to provision an instance of the Oracle Backend for Spring Boot and Microservices.

Estimated Time: 30 minutes

### About Oracle Backend for Spring Boot and Microservices

Oracle Backend for Spring Boot and Microservices allows developers to build microservices in Spring Boot and provision a backend as a service with the Oracle Database and other infrastructure components that operate on multiple clouds. This service vastly simplifies the task of building, testing, and operating microservices platforms for reliable, secure, and scalable enterprise applications.

This module provides three options for running the environment:

- **Locally in a container** - you will need a container platform like Docker Desktop, Rancher Desktop, Podman Desktop or similar.
  This option is recommended only if you have at least 64GB of RAM.  With less memory this option will probably be too slow.
- In a single compute instance in either an **Oracle Cloud Free Tier** account or any commercial OCI Cloud tenancy.  You can sign up for an [Oracle Cloud Free Tier account here](https://signup.cloud.oracle.com/).  This account will include enough free credits to run CloudBank. You can also use this option to run a lightweight, single compute instance environment in any Oracle Cloud tenancy.
- The full production-sized installation from OCI Marketplace in a commercial **Oracle Cloud tenancy**.  If you have a commercial
  tenancy with sufficient capacity and privileges, you can run the full production-sized installation.  This can be installed from
  the OCI Marketplace using the instructions in Module 1.  Check the instructions for a more detailed list of requirements.

Regardless of which option you choose, the remainder of the modules will be virtually identical.  

### Objectives

In this lab, you will:

* Provision an instance of Oracle Backend for Spring Boot and Microservices, either locally or in the cloud.

### Prerequisites

This module assumes you have either:

* An Oracle Cloud account in a tenancy with sufficient quota and privileges to create:
  * An OCI Container Engine for Kubernetes cluster, plus a node pool with three worker nodes
  * A VCN with at least two public IP’s available
  * A public load balancer
  * An Oracle Autonomous Database - Shared instance
  * At least one free OCI Auth Token (note that the maximum is two per user), or
* An Oracle Cloud Free Tier account, or
* A local machine with enough memory (64GB recommneded) to run the environment locally.