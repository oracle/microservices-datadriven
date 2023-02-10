---
title: "On-Premises Installation"
---

# On-Premises Installation

The Oracle Backend for Spring Boot is available is available to install On-Premises.  The On-Premises installation includes both a _Desktop_ installation and an _Estate_ installation.

The _Desktop_ installation can be used to explore the in a non-Production environment, while the _Estate_ installation is targeted for Production infrastructure.

## Prerequisites

You must meet the following prerequisites to use the Oracle Backend for Spring Boot On-Premises:

* Access to an Oracle Database - Enterprise Edition 21.3.0.0
* Access to a Container Repository
* Access to a Kubernetes Cluster
* [Python 3+](https://www.python.org/)

When installing on a _Desktop_ the above pre-requisites are met through an additional Setup task, but there are additional desktop system/software requirements:

* 2 CPUs or more
* 8GB of free memory
* 60GB of free disk space (40G minikube and container images, 20G database)
* Internet connection
* [Minikube](https://minikube.sigs.k8s.io/docs/start/)
* [Podman](https://podman.io/getting-started/)[^1]
* Oracle SSO Account to download the database image

## Download

Download Oracle Backend for Spring Boot.

## Setup

An On-Premises installation, whether _Desktop_ or _Estate_, consists of defining the Infrastructure followed by running the Configuration Management Playbook to build images and deploy the microservices.

For an _Estate_ installation, you need to have a Kubernetes cluster, and the kubectl command-line tool must be configured to communicate with your cluster.

A helper Playbook has been provided for the _Desktop_ installations to assist in defining the Infrastructure.  Please review the appropriate documentation for examples of installing and defining the _Desktop_ installation (more _Desktop_  examples may be provided in the future).

* [MacOS Ventura (x86)](ONPREM_MACOS_VENTURA.md)
* [Oracle Linux 8 (x86)](ONPREM_OL8.md)

The _Desktop_ Playbook will be run as part of the Configuration Management.

## Download the Database/ORDS Images (_Desktop_ Installation)

The _Desktop_ installation will provision an Oracle Database into the Kubernetes cluster.  The images must be downloaded from [Oracle's Container Registry](https://container-registry.oracle.com/) prior to continuing.

After Installing Podman:

1. Log into Oracle's Container Registry: `podman login container-registry.oracle.com`
2. Pull the Database Image: `podman pull container-registry.oracle.com/database/enterprise:21.3.0.0`
3. Pull the ORDS Image: `podman pull container-registry.oracle.com/database/ords:21.4.2-gh`

### Defining the Database  (_Estate_ Installation)

The database is defined in `ansible/roles/database/vars/main.yaml`.  Below is an example definition:  

```yaml
---
oracle_dbs: ['BAASPDB']
default_db: BAASPDB
BAASPDB:
  username: 'PDBADMIN'
  password: 'Correct-horse-Battery-staple-35'
  service: '(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=BAASPDB)))'
  wallet: ''
...
```

The `oracle_dbs` and `default_db` key values should be the name of your Pluggable Database (PDB).  These are followed by the PDB Name and key/values defining how to access the PDB.  If using mTLS authentication, specify the full path of the wallet file.

### Defining the Container Repository  (_Estate_ Installation)

The container repository is defined in `ansible/roles/registry/vars/main.yaml`.  Below is an example definition:

```yaml
---
compartment_ocid: ''
registry_username: 'oracle'
registry_password: 'Correct-horse-Battery-staple-35'
push_registry_url: 'docker.io/myorg'
pull_registry_url: 'docker.io/myorg'
registry_auth:
  auths:
    docker.io/myorg:
      auth: 'b3JhY2xlOjdaUVgxLXhhbFR0NTJsS0VITlA0'
    docker.io/myorg:
      auth: 'b3JhY2xlOjdaUVgxLXhhbFR0NTJsS0VITlA0'
...
```

Leave `compartment_ocid` blank for all On-Premises installations.  Specify the URL/authentication credentials for your Container Repository in `pull_registry_url`, `push_registry_url`, `registry_username` and `registry_password`.  

For the `registry_auth` section, manually log into your repository and copy the values found in file created, often found in `$HOME/.config/containers/auth.json`

You maybe curious as to why there is duplication between the push and pull URL's.  The pull URL is used inside the pods while the push is used from the deployment machine.  If you have a private registry inside the Kubernetes cluster, these URL's could be different.  This is the case for the _Desktop_ installation; the push URL is `localhost:5000`, while the pull URL is `<Registry Pod ClusterIP>:5000`.

## Configuration Management

From the source package, run the configuration management Playbook:

### Install Ansible

Using python, install Ansible to run the Configuration Management Playbook.  The helper scripts will create a Python Virtual Environment and install Ansible and additional modules:

```bash
./setup_ansible.sh
source ./activate.env
```

### Desktop Playbook

If this is an _Estate_ installation, the Infrastructure should be manually defined as per above.  

If this is a _Desktop_ installation; run the helper Playbook to define the infrastructure:

```bash
ansible-playbook ansible/desktop-apply.yaml
```

### Build and Push Images to the Container Repository

For the _Desktop_ installation, start a new terminal and tunnel to the minikube cluster:
`minikube tunnel`

For both installations, on the original terminal, run the Images Playbook:

```bash
ansible-playbook ansible/images_build.yaml
```

### Install the Microservices

```bash
ansible-playbook ansible/k8s_apply.yaml -t full
```

## Finish

Next, move on the the [Getting Started](../getting-started/) page to learn how to use the newly installed environment.

## Footnotes

[^1]: Certification has been performed against Podman, however, other container or virtual machine managers are available and may be substituted.  Experience is needed and your milage may vary.
