+++
archetype = "page"
title = "Configure Kubectl"
weight = 7
+++

At the end of the previous lab, during the verification of the installation, you looked at the end of the apply log and copied a command to obtain a Kubernetes configuration file to access your cluster.  In that lab, you used OCI CLoud Shell to confirm you could access the cluster.  Now, you need to configure similar access from your own development machine.   You can run that same command on your local machine, we recommend that you choose a different location for the file, so it does not overwrite or interfere with any other Kubernetes configuration file you might already have on your machine.

1. Create the Kubernetes configuration file

   Run the command provided at the end of your installation log to obtain the Kubernetes configuration file.  The command will be similar to this:

    ```shell
    $ oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.phx.xxxx --file path/to/kubeconfig --region us-phoenix-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
    ```

2. Configure **kubectl** to use the Kubernetes configuration file you just created

   Set the **KUBECONFIG** environment variable to point to the file you just created using this command (provide the path to where you created the file):

    ```shell
    $ export KUBECONFIG=/path/to/kubeconfig
    ```

3. Verify access to the cluster

   Check that you can access the cluster using this command:

    ```shell
    $ kubectl get pods -n obaas-admin
    NAME                          READY   STATUS    RESTARTS     AGE
    obaas-admin-bf4cd5f55-z54pk   2/2     Running   2 (9d ago)   9d
    ```

   Your output will be slightly different, but you should see one pod listed in the output.  This is enough to confirm that you have correctly configured access to the Kubernetes cluster.

