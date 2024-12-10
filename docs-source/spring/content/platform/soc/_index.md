---
title: "ServiceOps Center"
description: "Using ServiceOps Center to manage applications in Oracle Backend for Microservices and AI"
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
  - name: soc-diag-data
    src: "soc-diag-data.png"
    title: "Diagnostic Data"
  - name: soc-create-workload-details
    src: "soc-create-workload-details.png"
    title: "Workload Details"
  - name: soc-create-workload-db
    src: "soc-create-workload-db.png"
    title: "Database Details"
  - name: soc-create-workload-bind
    src: "soc-create-workload-bind.png"
    title: "Bind AQ JMS Event Queue"
  - name: soc-create-workload-route
    src: "soc-create-workload-route.png"
    title: "APISIX Route"
  - name: soc-create-workload-upload
    src: "soc-create-workload-upload.png"
    title: "Upload workload binary"
  - name: soc-create-workload-progress
    src: "soc-create-workload-progress.png"
    title: "Finish"
  - name: soc-manage-identity-create-user
    src: "soc-manage-identity-create-user.png"
    title: "Create User"
  - name: soc-manage-identity-chg-psswd
    src: "soc-manage-identity-chg-psswd.png"
    title: "Change Password"
  - name: soc-manage-identity-chg-role
    src: "soc-manage-identity-chg-role.png"
    title: "Change Roles"
  - name: soc-manage-identity-chg-email
    src: "soc-manage-identity-chg-email.png"
    title: "Change Email"
  - name: soc-forgot-passwd
    src: "soc-forgot-passwd.png"
    title: "Forgot Password"
  - name: soc-reset-psswd-otp
    src: "soc-reset-psswd-otp.png"
    title: "One-time password confirmation"
  - name: soc-forgot-username
    src: "soc-forgot-username.png"
    title: "Forgot Username"
  - name: soc-reset-psswd
    src: "soc-reset-psswd.png"
    title: "Reset Password"
  - name: soc-heartbeat
    src: "soc-heartbeat.png"
    title: "Usage Reporting"
  - name: soc-create-ns
    src: "soc-create-ns.png"
    title: "Create Namespace"
  - name: soc-delete-ns
    src: "soc-delete-ns.png"
    title: "Delete Namespace"
  - name: soc-delete-workload
    src: "soc-delete-workload.png"
    title: "Delete Workload"
  - name: soc-delete-user
    src: "soc-delete-user.png"
    title: "Delete User"
  - name: soc-alerts
    src: "soc-alerts.png"
    title: "Alerts"
  - name: soc-workload-details
    src: "soc-workload-details.png"
    title: "Workload Details"
  - name: soc-workload-details-overview
    src: "soc-workload-details-overview.png"
    title: "Workload Details: Overview"
  - name: soc-workload-details-overview-scale
    src: "soc-workload-details-overview-scale.png"
    title: "Workload Details: Scale workload"
  - name: soc-workload-details-hpa
    src: "soc-workload-details-hpa.png"
    title: "Workload Details: Horizontal Pod Autoscaler(HPA)"
  - name: soc-workload-details-hpa-create
    src: "soc-workload-details-hpa-create.png"
    title: "Workload Details: Create HPA"
  - name: soc-workload-details-route
    src: "soc-workload-details-route.png"
    title: "Workload Details: APISIX Routes"
  - name: soc-manage-config
    src: "soc-manage-config.png"
    title: "Manage Configuration"
  - name: soc-manage-config-create
    src: "soc-manage-config-create.png"
    title: "Create Configuration"
  - name: soc-manage-config-update
    src: "soc-manage-config-update.png"
    title: "Update Configuration"
  - name: soc-manage-config-delete
    src: "soc-manage-config-delete.png"
    title: "Delete Configuration"
---

Oracle Backend for Microservices and AI includes "ServiceOps Center". The ServiceOps Center provides a web user interface to manage the Oracle Backend for Microservices and AI. This release includes the following capabilities:

- View details about the configuration and health of the environment
- Manage and deploy workloads/microservices deployed in the environment
- Easy one-click access to Grafana dashboards for applications
- Manage users and roles defined in the Authorization Server included in the environment
- Easy one-click access to Grafana dashboards for the Kubernetes cluster, the applications and the Oracle Database
- Collect diagnostic data for support

**Note:** More capabilities will be added to this feature in future releases.

- [Accessing ServiceOps Center](#accessing-serviceops-center)
- [Login Screen](#login-screen)
  - [Forgot Password](#forgot-password)
  - [Reset Password](#reset-password)
  - [Forgot Username](#forgot-username)
- [The Dashboard](#the-dashboard)
  - [Manage Namespaces](#manage-namespaces)
    - [Create Namespace](#create-namespace)
    - [Delete Namespace(s)](#delete-namespaces)
  - [Manage Workloads](#manage-workloads)
    - [Create Workload](#create-workload)
      - [Service Details](#service-details)
      - [Database Details](#database-details)
      - [Bind resources](#bind-resources)
      - [APISIX route](#apisix-route)
      - [Upload workload binary](#upload-workload-binary)
      - [Progress screen](#progress-screen)
    - [Delete Workload(s)](#delete-workloads)
    - [Workload Details](#workload-details)
      - [Overview](#overview)
      - [Horizontal Pod Autoscaler](#horizontal-pod-autoscaler)
      - [APISIX Routes](#apisix-routes)
  - [Manage Identity](#manage-identity)
    - [Create User](#create-user)
    - [Change Password](#change-password)
    - [Change Roles](#change-roles)
    - [Change Email](#change-email)
    - [Delete User(s)](#delete-users)
  - [Manage Configuration](#manage-configuration)
    - [Create Configuration](#create-configuration)
    - [Update Configuration](#update-configuration)
    - [Delete Configuration(s)](#delete-configurations)
  - [Collect Diagnostic Data](#collect-diagnostic-data)
  - [Alerts](#alerts)
  - [Usage Reporting](#usage-reporting)

### SMTP Settings

The ServiceOps Center can send emails for following operations:

- [Forgot Password](#forgot-password)
- [Reset Password](#reset-password)
- [Forgot Username](#forgot-username)
- [Create User](#create-user)
- [Change Password](#change-password)
- [Change Roles](#change-roles)
- [Change Email](#change-email)

It is required to configure a SMTP secret as follows for the email functionality to work.

```bash
 kubectl -n obaas-admin create secret generic smtp-secret \
    --from-literal=SMTP_USER=<smtp-server-user> \
    --from-literal=SMTP_PASSWORD=<smtp-server-password> \
    --from-literal=SMTP_HOST=<smtp-server-address> \
    --from-literal=SMTP_PORT=<smtp-server-port> \
    --from-literal=SMTP_SECURE=<true-if-tls-port> \
    --from-literal=SMTP_FROM=<from-email-address>
```

## Accessing ServiceOps Center

To access the ServiceOps Center, obtain the public IP address for your environment using this command:

```bash
kubectl -n ingress-nginx get service ingress-nginx-controller
```

The output will be similar to this:

```text
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   10.96.172.148   xxx.xxx.xxx.xxx   80:31393/TCP,443:30506/TCP   158m
```

Use the `EXTERNAL-IP` from the results and open a browser to https://xxx.xxx.xxx.xxx/soc to access the login page.

**Note**: If you installed with self-signed certificates, which is the default, you will see a browser warning message and
will have to click on "Accept risk" or similar. For information about replacing the self-signed certificate with a
production certificate, refer to [Transport Layer Security](../../security#transport-layer-security)

## Login Screen

<!-- spellchecker-disable -->

{{< img name="soc-login-page" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

Login using the `obaas-admin` user (or another user if you have created one) and the password that you set during installation. If you did not set a password, one was auto-generated for you and can be obtained with this command:

```bash
kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d; echo
```

Login page also provides link to retrieve username, get a one-time password and reset password.

### Forgot Password

Click on "Forgot Password" to generate a One-time password which will be sent to your email (if configured)

<!-- spellchecker-disable -->

{{< img name="soc-forgot-passwd" size="medium" lazy=false >}}

{{< img name="soc-reset-psswd-otp" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Reset Password

The One-time password must be reset using the "Reset Password" link.

<!-- spellchecker-disable -->

{{< img name="soc-reset-psswd" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Forgot Username

Click the "Forgot Username" link to retrieve username in an Email.

<!-- spellchecker-disable -->

{{< img name="soc-forgot-username" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

After logging in, you will see the SOC Dashboard.

## The Dashboard

The ServiceOps Center Dashboard provides information about the overall state of the environment including:

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

The Manage Namespaces screen is accessible from the _Workloads_ menu, and allows you to view and manage the namespaces that are configured for microservice deployments. Note that this does not show you all namespaces in the Kubernetes cluster, just those that have be specifically configured for workloads, meaning they have the necessary secrets for pulling images, accessing the database, and so on.

<!-- spellchecker-disable -->

{{< img name="soc-manage-namespaces" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

Clicking on a namespace will allow you to drill down into that namespace and see the workloads/microservices
deployed there.

#### Create Namespace

You can click on the "CREATE" button to create a new namespace.

<!-- spellchecker-disable -->

{{< img name="soc-create-ns" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Delete Namespace(s)

To delete one or more of the namesapces, select from the grid and click "DELETE" button.

<!-- spellchecker-disable -->

{{< img name="soc-delete-ns" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Manage Workloads

The Manage Workloads screen shows the workloads/microservices deployed in a specific namespace, including
the status of each workload, and how many replicas are currently running and desired.

<!-- spellchecker-disable -->

{{< img name="soc-manage-workloads" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

You can click on the "open" link in the Dashboard column to open the Spring Boot Statistics Grafana dashboard for any workload listed in the table. Note that you may need to authenticate to Grafana the first time.

<!-- spellchecker-disable -->

{{< img name="soc-grafana-link" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

More details of this dashboard can be found [here](../../observability/metrics/#spring-boot-statistics).


#### Create Workload

You can click on the "CREATE" button to start the workload deployment wizard where you can provide configuration detail of the workload and upload workload binary. The wizard will have following screens:

##### Service Details

Provide basic details of the workload such as

- Name
- Version
- Spring profile to use
- Service Port
- Deployment replicas
- Java Base Image to be used or to use the default
- Name of database schema
- Whether to inject health probe and
- If needs to be deployed as a GraalVM native binary

<!-- spellchecker-disable -->

{{< img name="soc-create-workload-details" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### Database Details

Provide credentials of database schema and optional Spring binding prefix to be used.

<!-- spellchecker-disable -->

{{< img name="soc-create-workload-db" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### Bind resources

Optionally bind a JMS AQ Event Queue to the workload.

<!-- spellchecker-disable -->

{{< img name="soc-create-workload-bind" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### APISIX route

Specify APISIX route for the workload.

<!-- spellchecker-disable -->

{{< img name="soc-create-workload-route" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### Upload workload binary

Upload the workload jar/binary.

<!-- spellchecker-disable -->

{{< img name="soc-create-workload-upload" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### Progress screen

Next screen will show the progress of workload deployment and associated configurations being created in the cluster.

<!-- spellchecker-disable -->

{{< img name="soc-create-workload-progress" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Delete Workload(s)

To delete one or more workload, select and click "DELETE".

<!-- spellchecker-disable -->

{{< img name="soc-delete-workload" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Workload Details

To access details about a Workload, click on the name of the workload.

<!-- spellchecker-disable -->

{{< img name="soc-workload-details" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### Overview

The Overview section on the Workload details page contains basic details of the workload such as

- Name of the workload
- Image
- Ports exposed by the workload
- Link to the Spring Boot Statistics Grafana dashboard for the workload
- Spring profile
- Status of Health Probe
- CPU Resource request
- Name of the Liquibase database
- Workload creation/last update timestamps
- Replicas available
- Overall status of the workload.

The Overview section also provides buttons to control state of the workload. You can click START to start a workload which is currently unavailable. Click STOP to stop a running workload. DELETE can be used to permanently remove a workload from the cluster.

<!-- spellchecker-disable -->

{{< img name="soc-workload-details-overview" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

To scale the workload to a desired number of replicas, click SCALE and enter the number of replicas.

<!-- spellchecker-disable -->

{{< img name="soc-workload-details-overview-scale" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### Horizontal Pod Autoscaler

The Horizontal Pod Autoscaler section contains basic details of the [Horizontal Pod Autocaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) or HPA present for a workload such as

- Name
- Reference to target deployment
- Target metric value
- Minimum number of pods
- Maximum number of pods
- Current replicas
- Age of HPA

If a HPA exists, DELETE button can be used to delete the HPA.

<!-- spellchecker-disable -->

{{< img name="soc-workload-details-hpa" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

If no HPA exists for the workload, you can create one by clicking the CREATE button and entering HPA details.

<!-- spellchecker-disable -->

{{< img name="soc-workload-details-hpa-create" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

##### APISIX Routes

The APISIX Routes section Name, Path and Target port of [APISIX Route](https://apisix.apache.org/docs/apisix/terminology/route/) present for a workload.

<!-- spellchecker-disable -->

{{< img name="soc-workload-details-route" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Manage Identity

The Manage Identity screen is accessible from the Security menu and allows you to view and edit information about the users and roles defined in the Authorization Server included in the platform.

<!-- spellchecker-disable -->

{{< img name="soc-manage-identity" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Create User

You can click "CREATE" to create a new user and specify the password, roles and email.

<!-- spellchecker-disable -->

{{< img name="soc-manage-identity-create-user" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Change Password

You can select a user and click "CHANGE PASSWORD" to change password.

<!-- spellchecker-disable -->

{{< img name="soc-manage-identity-chg-psswd" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Change Roles

You can select a user and click "CHANGE ROLES" to add/remove roles.

<!-- spellchecker-disable -->

{{< img name="soc-manage-identity-chg-role" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Change Email

You can select a user and click "CHANGE EMAIL" to change Email.

<!-- spellchecker-disable -->

{{< img name="soc-manage-identity-chg-email" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Delete User(s)

You can select one or more users and click "DELETE" to delete selected user(s).

<!-- spellchecker-disable -->

{{< img name="soc-delete-user" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Manage Configuration

The Manage Configuration screen is accessible from the Config-Server menu and allows you to view and edit external configuration in [Spring Cloud Config server](../config).

<!-- spellchecker-disable -->

{{< img name="soc-manage-config" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Create Configuration

You can click "CREATE" to create a new configuration by specifying the application name, Spring profile, config label, key and its value. 

<!-- spellchecker-disable -->

{{< img name="soc-manage-config-create" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Update Configuration

You can select a configuration and click "UPDATE" to change its value.

<!-- spellchecker-disable -->

{{< img name="soc-manage-config-update" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

#### Delete Configuration(s)

You can select one or more configurations and click "DELETE" to delete selected configuration(s).

<!-- spellchecker-disable -->

{{< img name="soc-manage-config-delete" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Collect Diagnostic Data

The Collect Diagnostic Data is accessible from the Settings Menu and allows you to collect and download diagnostic data about your installation and platform. Verify its contents for any sensitive information before submitting with any support request.

<!-- spellchecker-disable -->

{{< img name="soc-diag-data" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Alerts

You can see preview of alerts from Alertmanager in ServiceOps Center. Clicking on an alert navigates to the Alertmanager UI. You can close individual alerts or click "Dismiss All" to close all the alerts. To re-enable the alerts, click "Show All Alerts" from the "Settings" menu.

<!-- spellchecker-disable -->

{{< img name="soc-alerts" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

### Usage Reporting

The ServiceOps Center can send basic install details to Oracle on a periodic basis, To enable that, click on the "AGREE" button on the notification or "CLOSE" to mute the notification. The details will include

- Memory, CPU count, nodes and version of the Kubernetes cluster
- Overall health status of the OBaaS platform
- Version of the OBaaS platform
- Database details such as name, CPU count and memory details

<!-- spellchecker-disable -->

{{< img name="soc-heartbeat" size="medium" lazy=false >}}

<!-- spellchecker-enable -->

