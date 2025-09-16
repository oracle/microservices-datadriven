---
title: Prepare and Install the OBaaS Database Helm chart
sidebar_position: 9
---
## Prepare and Install the OBaaS Database Helm chart

For this step, you will need the **obaas-db** directory in which you will see the following files:

```bash
cd obaas-db/
ls
Chart.yaml scripts templates values.yaml
```

You must edit the **values.yaml** file as follows:

- If you are using a private repository, you must update each **image** entry to point to your private repository instead of the public repositories.

- You must update the values in the **database.oci_config** section as follows:

  - The **oke** setting must be **false**. Setting this to true is not supported in 2.0.0-M3.

  - Supply your **tenancy**, **user** ocid, **fingerprint** and **region**. These must match the details you provided when you created the OCI configuration secret earlier. This information can be found in the OCI configuration file.

- (Optional) If you want to install any components in this chart into their own separate namespace, you can override the global namespace by setting a value in the **namespace** property inside the section for that component.

**Important note**: Please pause to double check all of the values are correct. If there are any errors here, the database provisioning will fail.

Install the Helm chart using the following command:

```bash
helm --debug install obaas-db --set global.obaasName="obaas-dev" --set global.targetNamespace="obaas-dev" ./
```

```text
NAME: obaas-db
LAST DEPLOYED: Sun Aug 17 13:09:20 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

When the installation has completed, you can use `helm ls` command to view the installed charts:

```text
NAME               	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART                    	APP VERSION
obaas-db           	default  	1       	2025-09-12 13:51:23.751199 -0500 CDT	deployed	OBaaS-db-0.1.0           	2.0.0-M3   
obaas-observability	default  	1       	2025-09-12 13:45:43.113298 -0500 CDT	deployed	OBaaS-observability-0.1.0	2.0.0-M3   
obaas-prereqs      	default  	1       	2025-09-12 13:37:16.026781 -0500 CDT	deployed	OBaaS-Prerequisites-0.0.1	2.0.0-M3  
```

If you overrode the namespace for this component, you will see a new namespace called **oracle-database-operator-system** (for example) and the following pods. Otherwise the pods will be in the **obaas-dev** namespace (or whatever name you chose). 

![DB Operator pods](media/image6.png)

**Note**: If you are installing multiple OBaaS instances in your cluster, each one MUST have a different release name, `obaasName` and `targetNamespace`.  For example:

For obaas-dev:

```bash
helm install obaas-db --set global.obaasName="obaas-dev" --set global.targetNamespace="obaas-dev" ./
```

For obaas-prod:

```bash
helm install obaas-prod-db --set global.obaasName="obaas-prod" --set global.targetNamespace="obaas-prod" ./
```
