---
title: "Custom Installations"
description: "Custom installations of Oracle Backend for Spring Boot and Microservices"
keywords: "installation onprem custom spring springboot microservices development oracle backend"
---

The Oracle Backend for Spring Boot and Microservices is available to install in your own "custom" environment, which may be an on-premises data center environment, a different cloud provider, or a developer's desktop.

## Prerequisites

You must meet the following prerequisites to use the Oracle Backend for Spring Boot and Microservices On-Premises. You need:

* Access to Oracle Database Enterprise Edition 21.3.0.0
* Access to a Container Repository
* Access to a Kubernetes cluster
* [Python 3+](https://www.python.org/)

When installing in a _non-production_ environment, for example a developer's desktop, the previously mentioned pre-requisites may be met through an additional setup task, but there are additional desktop system or software requirements. For example:

* 2 CPUs or more
* 8 GB of free memory
* 60 GB of free disk space (40 GB minikube and container images, 20 GB database)
* Internet connection
* [Minikube](https://minikube.sigs.k8s.io/docs/start/) or similar
* [Podman](https://podman.io/getting-started/)[^1] or simliar
* Oracle Single Sign-On (SSO) account to download the database image

## Download

Download the latest release of [Oracle Backend for Spring Boot and Microservices](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.1.0/onprem-ebaas_latest.zip).

## Setup

A custom installation, whether production or non-production, consists of defining the infrastructure followed by running the Configuration
Management Playbook to build images and deploy the Microservices.

For a production installation, you need to have a Kubernetes cluster and the `kubectl` command-line interface must be configured to
communicate with your cluster.

A Helper Playbook has been provided for non-production installations to assist in defining the infrastructure.  Review the
appropriate documentation for examples of installing and defining the non-production installation. For example:

* [macOS Ventura (x86)](macos_ventura/_index.md)
* [Oracle Linux 8 (x86)](ol8/_index.md)

The non-production playbook is run as part of the Configuration Management Playbook.

## Download the Database or Oracle REST Data Services (ORDS) Images (Desktop Installation)

The non-production installation provisions an Oracle database to the Kubernetes cluster. The images must be downloaded
from [Oracle's Container Registry](https://container-registry.oracle.com/) before continuing.

After installing Podman, process these steps:

1. Log in to Oracle Cloud Infrastructure Registry (Container Registry). For example:

   `podman login container-registry.oracle.com`

2. Pull the database image. For example:

   `podman pull container-registry.oracle.com/database/enterprise:19.3.0.0`

3. Pull the ORDS image. For example:

   `podman pull container-registry.oracle.com/database/ords:21.4.2-gh`

### Defining the Parse Application (Production Installation)

The application is defined in `ansible/vars/ebaas.yaml`. For example:

```yaml
---
---
ebaas_edition: "COMMUNITY"
vault: ""
vault_key: ""
vault_crypto_endpoint: ""
vault_management_endpoint: ""
vault_storage_account_name: "N/A"
vault_storage_account_key: "N/A"
vault_storage: ""
vault_storage_lock: ""
apisix_admin_password: "Correct-horse-Battery-staple-35"
grafana_admin_password: "Correct-horse-Battery-staple-35"
oractl_admin_password: "Correct-horse-Battery-staple-35"
oractl_user_password: "Correct-horse-Battery-staple-35"
...
```

### Defining the Database (Production Installation)

The database is defined in `ansible/roles/database/vars/main.yaml`. For example:

```yaml
---
database_oracle_dbs: ["BAASPDB"]
database_default_db: BAASPDB
BAASPDB: # noqa: var-naming[pattern]
  username: "PDBADMIN"
  password: "Correct-horse-Battery-staple-35"
  service: "(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=BAASPDB)))"
  ocid: ""
...
```

The `oracle_dbs` and `default_db` key values should be the name of your Pluggable Database (PDB). These are followed by the PDB
name and Key/Values defining how to access the PDB. If using Mutual Transport Layer Security (mTLS) authentication, specify the
full path of the wallet file.

### Defining the Container Repository (Production Installation)

The Container Repository is defined in `ansible/roles/registry/vars/main.yaml`. For example:

```yaml
---
registry_username: "oracle"
registry_password: "Correct-horse-Battery-staple-35"
registry_push_url: "docker.io/myorg"
registry_push_auth:
  auths:
    docker.io/myorg:
      auth: "b3JhY2xlOjdaUVgxLXhhbFR0NTJsS0VITlA0"
registry_pull_url: "docker.io/myorg"
registry_pull_auth:
  auths:
    docker.io/myorg:
      auth: "b3JhY2xlOjdaUVgxLXhhbFR0NTJsS0VITlA0"
...
```

Specify the URL or authentication credentials for your Container Repository in `registry_pull_url`, `registry_push_url`, `registry_username`, and `registry_password`.

For the `registry_pull_auth` and `registry_push_auth` sections, manually log into your repository and copy the values found in the created file, located in `$HOME/.config/containers/auth.json`

There may be duplication between the push and pull URL's. The pull URL is used inside the Pods while the push URL is used from the
deployment machine. If you have a private registry inside the Kubernetes cluster, these URL's could be different. This is the case for
the _Desktop_ installation. For example, the push URL is `localhost:5000`, while the pull URL is `<Registry Pod ClusterIP>:5000`.

## Configuration Management Playbook

From the source package, run the Configuration Management Playbook.

### Install Ansible

Using Python, install Ansible to run the Configuration Management Playbook.  The Helper script creates a Python virtual environment
and installs Ansible along with other additional modules. For example:

```bash
./setup_ansible.sh
source ./activate.env
```

### Non-production Playbook

If this is a production installation, then the infrastructure should be manually defined as previously stated.

If this is a non-production installation, then run the Helper Playbook to define the infrastructure. For example:

```bash
ansible-playbook ansible/desktop-apply.yaml
```

### Build and Push Images to the Container Repository

For the non-production installation, start a new terminal and tunnel or port-forward to the Minikube cluster.  Refer to the specific platform
details for more information.

For both installations, run the Images Playbook on the original terminal. For example:

```bash
ansible-playbook ansible/images_build.yaml
```

### Install the Microservices

Install the Microservices by running this command:

```bash
ansible-playbook ansible/k8s_apply.yaml -t full
```


## Footnotes

[^1]: Certification has been performed against Podman. However, other container or virtual machine managers are available and may be
substituted.
