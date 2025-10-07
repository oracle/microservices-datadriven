---
title: Introduction and Installation Flow
sidebar_position: 1
---
## Introduction and Installation flow

:::important
The installation flow is **VERY** important, you should follow the steps thoroughly. Do not move on to the next step if you have issues.
:::

Oracle Backend for Microservices and AI 2.0.0-M4 is an **internal-only** milestone release. It is not available externally. This release represents a milestone on the path to 2.0.0 -- it is not intended to be a "finished product" so you may encounter some minor issues, and this is expected. Please give feedback to the development team if you find
issues.

The 2.0.0-M4 release has the following key differences from the previous production release (1.4.0):

- Installation is performed with Helm instead of Ansible
- You may select which components you wish to install
- You may customize which namespaces you wish to install components into
- You may install more than one OBaaS instance in a cluster with this release, but see the restrictions below

Please note the following known issues in M3:

- Instance principal authentication for OKE worker nodes, which allows the Oracle Database Operator to manage Autonomous Database instances, may not work in this release
- This release has been tested on OKE; it has not been tested on OCNE.

The next release, 2.0.0-M5, is intended to be available approximately mid-October and will address some of these limitations.

**Important note:** Make sure that you have the correct kubectl config set. You can do this by exporting the `KUBECONFIG` variable and pointing to the correct config file.

### High Level Installation Flow

To install OBaaS, you will follow this high-level flow:

- Confirm environment meets prerequisites.
- Create required secrets.
- Create the namespace(s) for the OBaaS installation(s) if you're not going to use the default namespaces for each component.
- Prepare then install the OBaaS Prerequisites Helm chart and verify (once per cluster).
- These steps would be repeated once for EACH instance of OBaaS to install:
  - Optionally prepare then install the OBaaS Observability Helm chart and verify.
  - Prepare then install the OBaaS Database Helm chart and verify.
  - Prepare then install the OBaaS Helm chart and verify.
  - Optionally install the CloudBank sample application and verify.

**Important note**: If you want to install in an environment that does not have access to public container repositories, you must first obtain the required images and push them into your private repository.

The script file **private_repo_helper.sh** in the installation package can be used to pull all the required images and push them into your private repository. Note that you may need to run it once while off VPN to allow it to pull the images and ignore push errors. Then run it again on VPN and ignore the pull errors (if any).
