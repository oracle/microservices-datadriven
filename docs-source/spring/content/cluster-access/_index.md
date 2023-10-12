---
title: "Kubernetes Access"
resources:
  - name: oci-cloud-shell
    src: "oci-cloud-shell.png"
    title: "OCI Cloud Shell icon"
---

The Oracle Backend for Spring Boot and Microservices setup creates a Kubernetes cluster where the server and dashboard components are deployed. At the end
of setup, you are provided with a command in the log for the apply job to create a Kubernetes configuration file to access that cluster:

{{< hint type=[tip] icon=gdoc_check title=Tip >}}
For more information about working with the Kubernetes cluster, see [Setting Up Cluster Access](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#localdownload) in the Oracle Cloud Infrastructure documentation.
{{< /hint >}}

</br>

```txt
kubeconfig_cmd = "oci ce cluster create-kubeconfig
                    --cluster-id ocid1.cluster.oc1.iad.xxx
                    --file $HOME/.kube/config
                    --region us-ashburn-1
                    --token-version 2.0.0
                    --kube-endpoint PUBLIC_ENDPOINT"
```

**NOTE:** The generated `kubeconfig` file works if you are using the `DEFAULT` profile in your Oracle Cloud Infrastructure (OCI) CLI
configuration file. If you are using a different OCI CLI profile, you must add `--profile <PROFILE-NAME>` to the command. For example:

```txt
kubeconfig_cmd = "oci ce cluster create-kubeconfig
                    --cluster-id ocid1.cluster.oc1.iad.xxx
                    --file $HOME/.kube/config
                    --region us-ashburn-1
                    --token-version 2.0.0
                    --kube-endpoint PUBLIC_ENDPOINT"
                    --profile <PROFILE-NAME>
```

You must also edit the the generated Kubernetes configuration file and add the following lines:

```yaml
- name: user-xxxx
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - ce
      - cluster
      - generate-token
      - --cluster-id
      - ocid1.cluster....xxxx
      - --region
      - us-ashburn-1
      - --profile
      - <PROFILE-NAME>
      command: oci
```

### Using OCI Cloud Shell

A simple alternative is to use the [OCI Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm), which is
provided in the OCI Console. You can open the OCI Cloud Shell by clicking **Developer Tools** in the upper right corner of the OCI Console.
For example:

<!-- spellchecker-disable -->
{{< img name="oci-cloud-shell" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

Run the provided command to create your Kubernetes configuration file after which you can access the Kubernetes cluster. For example, you can
list the Pods in your cluster:

```cmd
Welcome to Oracle Cloud Shell.

Update: Cloud Shell will now use Oracle JDK 11 by default. To change this, see Managing Language Runtimes in the Cloud Shell documentation.

Your Cloud Shell machine comes with 5GB of storage for your home directory. Your Cloud Shell (machine and home directory) are located in: US East (Ashburn).
You are using Cloud Shell in tenancy xxxx as an OCI user xxxx

Type `help` for more info.
user@cloudshell:~ (us-ashburn-1)$ oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.iad.xxx
 --file $HOME/.kube/config --region us-ashburn-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
Existing Kubeconfig file found at /home/user/.kube/config and new config merged into it
user@cloudshell:~ (us-ashburn-1)$ kubectl get pods -A
NAMESPACE         NAME                                        READY   STATUS      RESTARTS        AGE
ingress-nginx     ingress-nginx-controller-7d45557d5c-bqwwp   1/1     Running     0               4h18m
ingress-nginx     ingress-nginx-controller-7d45557d5c-klgnb   1/1     Running     0               4h18m
ingress-nginx     ingress-nginx-controller-7d45557d5c-l4d2m   1/1     Running     0               4h18m
kube-system       coredns-746957c9c6-hwnm8                    1/1     Running     0               4h27m
kube-system       csi-oci-node-kqf5x                          1/1     Running     0               4h23m
kube-system       kube-dns-autoscaler-6f789cfb88-7mptd        1/1     Running     0               4h27m
kube-system       kube-flannel-ds-hb6ld                       1/1     Running     1 (4h22m ago)   4h23m
kube-system       kube-proxy-v5qwm                            1/1     Running     0               4h23m
kube-system       proxymux-client-vpnh7                       1/1     Running     0               4h23m
.........
user@cloudshell:~ (us-ashburn-1)$
```
