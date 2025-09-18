---
title: Prerequisites
sidebar_position: 2
---
## Prerequisites for Oracle Backend for Microservices and AI

To install OBaaS 2.0.0-M3, you must meet the following prerequisites:

- A CNCF-compliant Kubernetes cluster with working storage provider that provides a storage class for RWX PVs, and ingress. Version 1.33.1. At least 3 worker nodes. At least 2 OCPU and 32GB memory per worker node (this allows for ONE installation of OBaaS and some applications.  As a general rule of thumb, double the number of worker nodes if you want to install TWO OBaaS instances. You may need more if you want to install additional applications). OKE "quick create/enhanced" cluster recommended.
- An Oracle Database. Must be version 19c or later. If you want to use the AI features, it must be 23ai. Oracle Autonomous Database 23ai ATP with 2 ECPU and 1TB storage with "secure access from anywhere recommended.
- If you plan to use a private image repository, the images must be copied there. OBaaS provides a helper script, `private_repo_helper.sh`, to perform this task.

**Important note:** If your environment does not meet the prerequisites, the installation will fail. Please do not continue with installation until you have confirmed your environment meets the requirements.

If you use the recommended OKE cluster, your cluster should contain the following namespaces:

```bash
kubectl get ns
```

```log
NAME            STATUS  AGE
default         Active  4m52s
kube-node-lease Active  4m52s
kube-public     Active  4m52s
kube-system     Active  4m52s
```
