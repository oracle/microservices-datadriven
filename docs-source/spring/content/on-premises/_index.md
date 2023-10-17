---
title: "On-Premises Installation"
---

The Oracle Backend for Spring Boot and Microservices is available to install On-Premises. The On-Premises installation includes both a _Desktop_ installation
and an _Estate_ installation.

The _Desktop_ installation can be used to explore in a non-production environment, while the _Estate_ installation is targeted for the
production infrastructure.

## Prerequisites

You must meet the following prerequisites to use the Oracle Backend for Spring Boot and Microservices On-Premises. You need:

* Access to Oracle Database Enterprise Edition 21.3.0.0
* Access to a Container Repository
* Access to a Kubernetes cluster
* [Python 3+](https://www.python.org/)

When installing on a _Desktop_, the previously mentioned pre-requisites are met through an additional Setup task, but there are additional
desktop system or software requirements. For example:

* 2 CPUs or more
* 8 GB of free memory
* 60 GB of free disk space (40 GB minikube and container images, 20 GB database)
* Internet connection
* [Minikube](https://minikube.sigs.k8s.io/docs/start/)
* [Podman](https://podman.io/getting-started/)[^1]
* Oracle Single Sign-On (SSO) account to download the database image

## Download

Download [Oracle Backend for Spring Boot and Microservices](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/onprem-ebaas_latest.zip).

## Setup

An On-Premises installation, whether _Desktop_ or _Estate_, consists of defining the infrastructure followed by running the Configuration
Management Playbook to build images and deploy the Microservices.

For an _Estate_ installation, you need to have a Kubernetes cluster and the `kubectl` command-line interface must be configured to
communicate with your cluster.

A Helper Playbook has been provided for the _Desktop_ installations to assist in defining the infrastructure.  Review the
appropriate documentation for examples of installing and defining the _Desktop_ installation. For example:

* [macOS Ventura (x86)](macos_ventura/_index.md)
* [Oracle Linux 8 (x86)](ol8/_index.md)

The _Desktop_ playbook is run as part of the Configuration Management Playbook.

## Download the Database or Oracle REST Data Services (ORDS) Images (Desktop Installation)

The _Desktop_ installation provisions an Oracle database to the Kubernetes cluster. The images must be downloaded
from [Oracle's Container Registry](https://container-registry.oracle.com/) before continuing.

After installing Podman, process these steps:

1. Log in to Oracle Cloud Infrastructure Registry (Container Registry). For example:

   `podman login container-registry.oracle.com`

2. Pull the database image. For example:

   `podman pull container-registry.oracle.com/database/enterprise:19.3.0.0`

3. Pull the ORDS image. For example:

   `podman pull container-registry.oracle.com/database/ords:21.4.2-gh`

### Defining the Parse Application (Estate Installation)

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

### Defining the Database (Estate Installation)

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

### Defining the Container Repository (Estate Installation)

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

### Desktop Playbook

If this is an _Estate_ installation, then the infrastructure should be manually defined as previously stated.

If this is a _Desktop_ installation, then run the Helper Playbook to define the infrastructure. For example:

```bash
ansible-playbook ansible/desktop-apply.yaml
```

### Build and Push Images to the Container Repository

For the _Desktop_ installation, start a new terminal and tunnel or port-forward to the Minikube cluster.  Refer to the specific platform
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

Next, go to the [macOS Ventura](../on-premises/macos_ventura/) page to learn more.

## Footnotes

[^1]: Certification has been performed against Podman. However, other container or virtual machine managers are available and may be
substituted.
