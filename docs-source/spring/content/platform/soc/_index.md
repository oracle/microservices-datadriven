---
title: "Spring Operations Center"
description: "Using Spring Operations Center to manage applications in Oracle Backend for Spring Boot and Microservices"
keywords: "soc operations admin springboot spring development microservices development oracle backend"
resources:
  - name: soc-login-page
    src: "soc-login-page.png"
    title: "SOC Login Page"
  - name: soc-dashboard
    src: "soc-dashboard.png"
    title: "SOC Dashboard"
  - name: soc-manage-namespaces
    src: "soc-manage-namespaces.png"
    title: "SOC Manage Namespaces screen"
  - name: soc-manage-workloads
    src: "soc-manage-workloads.png"
    title: "SOC Manage Workloads screen"
  - name: soc-grafana-link
    src: "soc-grafana-link.png"
    title: "Grafana Dashboard for Workload"  
  - name: soc-manage-identity
    src: "soc-manage-identity.png"
    title: "SOC Manage Identity screen"
---


Oracle Backend for Spring Boot and Microservices version 1.1.3 includes a preview of a new feature called "Spring Operations Center".
More capabilities will be added to this feature in future releases.

The Spring Operations Center provides a web user interface to manage the Oracle Backend for Spring Boot and Microservices.
This preview release includes the following capabilities:

- View details about the configuration and health of the environment
- View details of workloads (Spring Boot applications) deployed in the environment
- Easy one-click access to Grafana dashboards for applications
- View details of users and roles defined in the Spring Authorization Server included in the environment
- Easy one-click access to Grafana dashboards for the Kubernetes cluster and the Oracle Database

**Note:** More capabilities will be added to this feature in future releases.

- [Accessing Spring Operations Center](#accessing-spring-operations-center)
- [The Dashboard](#the-dashboard)
  - [Manage Namespaces](#manage-namespaces)
  - [Manage Workloads](#manage-workloads)
  - [Manage Identity](#manage-identity)

## Accessing Spring Operations Center

To access the Spring Operations Center, obtain the public IP address for your environment using this command:

```bash
$ kubectl -n ingress-nginx get service ingress-nginx-controller
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   10.96.172.148   100.200.100.200   80:31393/TCP,443:30506/TCP   158m
```

Use the `EXTERNAL-IP` from the results and open a browser to https://100.200.100.200/soc to access the login page.

**Note**: If you installed with self-signed certificates, which is the default, you will see a browser warning message and
will have to click on "Accept risk" or similar. For information about replacing the self-signed certificate with a
production certificate, refer to [Transport Layer Security](../../security#transport-layer-security)

<!-- spellchecker-disable -->
{{< img name="soc-login-page" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

Login using the `obaas-admin` user (or another user if you have created one) and the password that you set during installation.  If you did not set a password, one was auto-generated for you and can be obtained with this command:

```bash
$ kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
```

After logging in, you will see the SOC Dashboard.

## The Dashboard

The Spring Operations Center Dashboard provides information about the overall state of the environment including:

- The version and platform the environment is running on
- The configuration and sizing of the Kubernetes cluster
- The configuration and sizing of the Database instance
- Easy one-click access to Grafana dashboards to see detailed status of the Kubernetes cluster and Database instance
- The overall system health status
- How many applications are deployed in the environment

<!-- spellchecker-disable -->
{{< img name="soc-dashboard" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

### Manage Namespaces

The Manage Namespaces screen is accessible from the *Workloads* menu, and allows you to view and manage the namespaces that are configured for Spring Boot application deployments.  Note that this does not show you all namespaces in the Kubernetes cluster, just those that have be specifically configured for Spring Boot workloads, meaning they have the necessary secrets for pulling images, accessing the database, and so on.

<!-- spellchecker-disable -->
{{< img name="soc-manage-namespaces" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

Clicking on a namespace will allow you to drill down into that namespace and see the workloads (Spring Boot applications)
deployed there.

### Manage Workloads

The Manage Workloads screen shows the workloads (Spring Boot applications) deployed in a specific namespace, including
the status of each workload, and how many replicas are currently running and desired.

<!-- spellchecker-disable -->
{{< img name="soc-manage-workloads" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

You can click on the "open" link in the Dashboard column to open the Spring Boot Statistics Grafana dashboard for any workload listed in the table.  Note that you may need to authenticate to Grafana the first time.

<!-- spellchecker-disable -->
{{< img name="soc-grafana-link" size="medium" lazy=false >}}
<!-- spellchecker-enable -->

More details of this dashboard can be found [here](../../observability/metrics/#spring-boot-statistics).

### Manage Identity

The Manage Identity screen is accessible from the Security menu and allows you to view information
about the users and roles defined in the Spring Authorization Server included in the platform.

<!-- spellchecker-disable -->
{{< img name="soc-manage-identity" size="medium" lazy=false >}}
<!-- spellchecker-enable -->
