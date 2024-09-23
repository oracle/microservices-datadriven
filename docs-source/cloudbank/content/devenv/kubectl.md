+++
archetype = "page"
title = "Install Kubectl and OCI CLI"
weight = 6
+++

In later labs, you will look various resources in the Kubernetes cluster and access some of them using port forwarding (tunneling).  To do this, you will need to install **kubectl** on your machine, and since Oracle Container Engine for Kubernetes uses token based authentication for **kubectl** access, you will also need to install the OCI CLI so that **kubectl** can obtain the necessary token.

1. Install **kubectl**

   Install **kubectl** from [the Kubernetes website](https://kubernetes.io/docs/tasks/tools/).  Click on the link for your operating system and follow the instructions to complete the installation.  As mentioned in the instructions, you can use this command to verify the installation, and you can ignore the warning since we are just checking the installation was successful (your output may be slightly different):

    ```shell
    $ kubectl version --client
    I0223 08:40:30.072493   26355 versioner.go:56] Remote kubernetes server unreachable
    WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short.  Use --output=yaml|json to get the full version.
    Client Version: version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.1", GitCommit:"3ddd0f45aa91e2f30c70734b175631bec5b5825a", GitTreeState:"clean", BuildDate:"2022-05-24T12:26:19Z", GoVersion:"go1.18.2", Compiler:"gc", Platform:"linux/amd64"}
    Kustomize Version: v4.5.4
    ```

2. Install the OCI CLI

   Install the OCI CLI from [the Quickstart documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).  Click on the link for your operating system and follow the instructions to complete the installation.  After installation is complete, use this command to verify the installation (your output might be slightly different):

    ```shell
    $ oci --version
    3.23.2
    ```

3. Configure the OCI CLI

   Review the instructions [in the documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliconfigure.htm) for configuring the OCI CLI.  The simplest way to configure the CLI is to use the guided setup by running this command:

    ```shell
    $ oci setup config
    ```

   This will guide you through the process of creating your configuration file.  Once you are done, check that the configuration is good by running this command (note that you would have obtained the tenancy OCID during the previous step, and your output might look slightly different):

    ```shell
    $ oci iam tenancy  get --tenancy-id ocid1.tenancy.oc1..xxxxx
    {
      "data": {
        "description": "mytenancy",
        "freeform-tags": {},
        "home-region-key": "IAD",
        "id": "ocid1.tenancy.oc1..xxxxx",
        "name": "mytenancy",
        "upi-idcs-compatibility-layer-endpoint": null
      }
    }
    ```

