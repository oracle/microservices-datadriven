---
title: Create Namespace(s) for OBaaS
sidebar_position: 6
---
## Create the namespace(s) for the OBaaS installation(s)

EACH instance of OBaaS must be installed in its own dedicated/unique namespace.

**Note**: You will only install the **obaas-prereqs** chart once per cluster, all other charts are installed once per OBaaS instance. The **obaas-prereqs** chart contains items that are cluster-wide and shared by all OBaaS instances in a cluster. If you are going to install multiple OBaaS instances (which is not supported in 2.0.0-M3) we recommend that you put the **obaas-prereqs** chart in its own namespace, separate from all OBaaS instances.

To create the namespace(s), use the following command(s).  For example, to create two installations called `obaas-dev` and `obbas-prod`:

```bash
kubectl create ns obaas-dev
```

```bash
kubectl create ns obaas-prod
```

Change the value to the desired name(s).
