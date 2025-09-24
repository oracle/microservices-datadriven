---
title: Prepare then install OBaaS Prerequisites Helm chart
sidebar_position: 7
---
## Prepare then install OBaaS Prerequisites Helm chart

For this step, you will need the **obaas-prereqs** directory, which contains the following files:

```bash
cd obaas-prereqs/
ls
Chart.yaml LICENSE README.md templates values.yaml
```

You must edit the **values.yaml** file as follows:

- If you are using a private repository, you must update each **image** entry to point to your private repository instead of the public repositories.
- Optional. Each component listed in the file (e.g., kube-state-metrics, metrics-server, cert-manager, etc.) has an **enabled: true** entry. If you want to omit a component, you must change the setting to **false**. Please note the following limitations:
- Metrics-server is required if you wish to use the Horizontal Pod Autoscaling feature.
- Cert-manager is required.

Choose a name for this OBaaS installation. In this document, we use **obaas-dev** as the name. Please note that the **targetNamespace** should match the namespace you created in the previous step, and that this namespace must already exist.

Install the Helm chart using the following command (The `--debug` flag is optional and enables verbose output from Helm):

```bash
helm --debug install obaas-prereqs ./
```

```log
NAME: obaas-prereqs
LAST DEPLOYED: Sun Aug 17 12:47:51 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

In this command, note that **obaas-prereqs** is the name of the Helm release.  Note that obaas-prereqs is shared across all instances in the cluster, so we recommend that you do NOT set the `obaasName` and `targetNamespace` for this chart/release.

When the installation has completed, you can use this command to view the installed charts:

```bash
helm ls
```

```text
NAME         	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART                    	APP VERSION
obaas-prereqs	default  	1       	2025-09-12 13:37:16.026781 -0500 CDT	deployed	OBaaS-Prerequisites-0.0.1	2.0.0-M3  
```

If you overrode the individual component namespaces, you should now see the requested namespaces have been added (for example see below). Otherwise, all of the pods will be in the **obaas-dev** namespace (or whatever name you chose).

```bash
kubectl get ns
```

```log
NAME                STATUS AGE
cert-manager        Active 3m37s
default             Active 77m
external-secrets    Active 3m37s
ingress-nginx       Active 3m54s
kube-node-lease     Active 77m
kube-public         Active 77m
kube-state-metrics  Active 3m37s
kube-system         Active 77m
metrics-server      Active 3m37s
```

And you should see the following pods running (note that they may take a few minutes to reach running and ready status):

```bash
kubectl get pods --A
```

```text
NAMESPACE            NAME                                                READY   STATUS    RESTARTS   AGE
cert-manager         cert-manager-7fbd576ffd-tzkmj                       1/1     Running   0          45s
cert-manager         cert-manager-cainjector-68f4656fdc-hfdw8            1/1     Running   0          45s
cert-manager         cert-manager-webhook-5cb89bf75b-h6sdr               1/1     Running   0          45s
external-secrets     external-secrets-6687559cc7-5xjbx                   1/1     Running   0          45s
external-secrets     external-secrets-cert-controller-79785cb877-fjd59   1/1     Running   0          45s
external-secrets     external-secrets-webhook-945df75bf-9zjqp            1/1     Running   0          45s
ingress-nginx        ingress-nginx-controller-j9bdk                      1/1     Running   0          45s
ingress-nginx        ingress-nginx-controller-splg7                      1/1     Running   0          45s
ingress-nginx        ingress-nginx-controller-x2wpz                      1/1     Running   0          45s
kube-state-metrics   kube-state-metrics-784bc85fd8-9fn5k                 1/1     Running   0          45s
kube-system          coredns-5b559d56fd-772r7                            1/1     Running   0          23h
kube-system          coredns-5b559d56fd-m5hx7                            1/1     Running   0          23h
kube-system          coredns-5b559d56fd-w85nh                            1/1     Running   0          23h
kube-system          csi-oci-node-6qkgt                                  1/1     Running   0          23h
kube-system          csi-oci-node-h4cnh                                  1/1     Running   0          23h
kube-system          csi-oci-node-qxrqc                                  1/1     Running   0          23h
kube-system          kube-dns-autoscaler-5bbc657c97-gr45f                1/1     Running   0          23h
kube-system          kube-proxy-64h2t                                    1/1     Running   0          23h
kube-system          kube-proxy-vcvhn                                    1/1     Running   0          23h
kube-system          kube-proxy-zlzxd                                    1/1     Running   0          23h
kube-system          proxymux-client-52pq8                               1/1     Running   0          23h
kube-system          proxymux-client-95jzz                               1/1     Running   0          23h
kube-system          proxymux-client-s54g9                               1/1     Running   0          23h
kube-system          vcn-native-ip-cni-5lqxn                             2/2     Running   0          23h
kube-system          vcn-native-ip-cni-chb42                             2/2     Running   0          23h
kube-system          vcn-native-ip-cni-d7thh                             2/2     Running   0          23h
metrics-server       metrics-server-77ff598cd8-b8nt8                     1/1     Running   0          45s
metrics-server       metrics-server-77ff598cd8-bnnld                     1/1     Running   0          45s
metrics-server       metrics-server-77ff598cd8-t6nx8                     1/1     Running   0          45s
```
