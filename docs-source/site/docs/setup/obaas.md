---
title: Prepare and Install the OBaaS Helm chart
sidebar_position: 10
---
## Prepare and Install the OBaaS Helm chart

For this step, you will need the **obaas** directory in which you will see the following files:

```bash
cd obaas/
ls
Chart.yaml LICENSE README.md crds templates values.yaml
```

You must edit the **values.yaml** file as follows:

- If you are using a private repository, you must update each **image** entry to point to your private repository instead of the public repositories.

- Optional. Each component listed in the file (e.g., apisix, kafka, coherence, etc.) has an **enabled: true** entry. If you want to omit a component, you must change the setting to **false**.

- (Optional) If you want to install any components in this chart into their own separate namespace, you can override the global namespace by setting a value in the **namespace** property inside the section for that component.

- You must provide the OCID of your ADB-S instance in the setting **database.oci_db.ocid**
- You must update the values in the **database.oci_config** the section as follows:
  - The **oke** setting must be **false**. Setting this to true is not supported in 2.0.0-M3.
  - Supply your **tenancy**, **user** **ocid**, **fingerprint** and **region**. These must match the details you provided when you created the OCI configuration secret earlier.

**Important note**: Please pause to double check all of the values are correct. If there are any errors here, the OBaaS provisioning will fail.

Install the Helm chart using the following command (The `--debug` flag is optional and enables verbose output from Helm):

```bash
helm --debug install obaas --set global.obaasName="obaas-dev" --set global.targetNamespace="obaas-dev" ./
```

```log
I0817 13:21:41.363368 5981 warnings.go:110\] "Warning: unknown field
"spec.serviceName""
I0817 13:21:41.439521 5981 warnings.go:110\] "Warning: unknown field
"spec.serviceName""
I0817 13:21:41.439531 5981 warnings.go:110\] "Warning: unknown field
"spec.serviceName""
NAME: obaas
LAST DEPLOYED: Sun Aug 17 13:21:15 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

You may see some warnings, as shown above, and they can be ignored in 2.0.0-M3.

If you overrode the component namespaces, you will now see several new namespaces as requested (see example below). Otherwise all of the pods will be in the **obaas-dev** namespace (or whatever name you chose):

```bash
kubectl get ns
```

```log
NAME                               STATUS AGE
admin-server                       Active 32s
apisix                             Active 32s
application                        Active 32s
azn-server                         Active 32s
cert-manager                       Active 33m
coherence                          Active 32s
conductor-server                   Active 32s
config-server                      Active 32s
default                            Active 107m
eureka                             Active 32s
external-secrets                   Active 33m
ingress-nginx                      Active 34m
kafka                              Active 32s
kube-node-lease                    Active 107m
kube-public                        Active 107m
kube-state-metrics                 Active 33m
kube-system                        Active 107m
metrics-server                     Active 33m
obaas-admin                        Active 32s
observability                      Active 22m
oracle-database-exporter           Active 32s
oracle-database-operator-system    Active 12m
otmm                               Active 32s
```

And many new pods. Note that these will take about 5 minutes for them all to get to ready/running status:

```bash
kubectl get pod -A
```

**Note**: If you are installing multiple OBaaS instances in your cluster, each one MUST have a different release name, `obaasName` and `targetNamespace`. For example (The `--debug` flag is optional and enables verbose output from Helm):

For obaas-dev:

```bash
helm --debug install obaas --set global.obaasName="obaas-dev" --set global.targetNamespace="obaas-dev" ./
```

For obaas-prod:

```bash
helm --debug install obaas --set global.obaasName="obaas-prod" --set global targetNamespace="obaas-prod" ./
```

**Note**: You MUST set different host names and/or ports for the APISIX ingress if you choose to install APISIX in both instances.
