---
title: Obtaining installation package
sidebar_position: 3
---
## Obtaining the Installation Package

The installation package is in the [helm](http://tbd) directory which  contains the following directories:

```text
.
├── obaas
├── obaas-db
├── obaas-observability
└── obaas-prereqs
```

Each of these directories contains a helm chart. In this milestone release, there are four helm charts:

- **OBaaS Prerequisites** This chart contains components that are installed at the cluster level and would be shared by all OBaaS installations in a cluster. This chart can only be installed once per cluster.

- **OBaaS Database**. This chart contains components that manage the OBaaS Database.

- **OBaaS Observability**. This chart contains components for the option OBaaS observability stack (based on SigNoz).

- **OBaaS**. This chart contains the remaining components of OBaaS, most notably the OBaaS Platform Services (like Eureka, Spring Config Server, Admin Server, etc.)
