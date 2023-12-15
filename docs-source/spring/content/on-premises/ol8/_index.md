---
title: "On-Premises Installation - Oracle Linux 8 (x86)"
---

This is an description of installing on a Oracle Linux 8 desktop.

Read the [On-Premises](../../on-premises) documentation and ensure that your desktop meets the minimum system requirements.

## Setup

### Create a Non-Root User

Create a new user. While any user name can be created, the rest of this documentation refers to the non-root user as `obaas`:

As `root`, process the following:

```bash
useradd obaas
```

### Download Oracle Backend for Spring Boot and Microservices

Download [Oracle Backend for Spring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.1/onprem-ebaas_latest.zip) and unzip into a new directory.

As the `obaas` user, run this command:

```bash
unzip onprem-ebaas_latest.zip -d ~/obaas
```

### Update the OS

Assuming the source was unzipped to `~obaas/obaas`, as the `root` user, update the OS by running the `ol8_onprem.sh` script from the unzipped package:

```bash
~obaas/obaas/ol8_onprem.sh
```

This script will perform the following actions:

* Install required OS Packages
* Install Minikube
* Set Python3 as the default ptyhon
* Enable cgroup v2
* Enable IP Tables
* Update the container runtime configuration

### Reboot

After the OS has been updated, `reboot` the host.

## Install

The remaining steps require **direct login** as the `obaas` user without using `sudo` or `su`.  Depending on whether the system is remote or local, this can be achieved by giving the `obaas` user a password (e.g. `passwd`) or setting up ssh-key authentication to the `obaas` user.

### Download the Database or Oracle REST Data Services (ORDS) Images

The _Desktop_ installation provisions an Oracle database into the Kubernetes cluster. The images must be downloaded
from [Oracle Cloud Infrastructure Registry (Container Registry)](https://container-registry.oracle.com/) before continuing.

While directly logged into the `obaas` user, process these steps:

1. Log in to the Container Registry. For example:

   `podman login container-registry.oracle.com`

2. Pull the database image. For example:

   `podman pull container-registry.oracle.com/database/enterprise:19.3.0.0`

3. Pull the ORDS image. For example:

   `podman pull container-registry.oracle.com/database/ords:21.4.2-gh`

#### Troubleshooting

If the `podman pull` fails, navigate in a web browser to https://container-registry.oracle.com, click the "database" tile and select "enterprise".  On the right hand side of the page, if prompted, sign-in.  Select "Language" and accept the Terms.  Try the `podman pull` again.

### Start MiniKube

While directly logged into the `obaas` user, run these commands:

```bash
minikube config set rootless true
minikube config set driver podman
minikube start --cpus max --memory 16G --disk-size='40g' --container-runtime=containerd
minikube addons enable ingress
echo "KUBECONFIG=~/.kube/config" >> ~/.bashrc
```

### Install Ansible

While directly logged into the `obaas` user, change to the source directory and install Ansible by running these commands:

```bash
cd ~/obaas
./setup_ansible.sh
source ./activate.env
```

### Define the Infrastructure

Use the Helper Playbook to define the infrastructure. This Playbook also:

* Creates additional namespaces for the Container Registry and database.
* Creates a private Container Registry in the Kubernetes cluster.
* Modifies the Microservices application to be desktop compatible.

Assuming the source was unzipped to `~/obaas`, run the following command as the `obaas` user:

`ansible-playbook ~/obaas/ansible/desktop_apply.yaml`

### Open a Tunnel

In order to push the images to the Container Registry in the Kubernetes cluster, open a new terminal and process this command while directly logged into the `obaas` user:

```bash
cd ~/obaas
source ./activate.env
kubectl port-forward service/private -n container-registry 5000:5000  > /dev/null 2>&1 &
```

### Build the Images

Build and push the images to the Container Registry in the Kubernetes cluster.

Assuming the source was unzipped to `~/obaas`, run the following command as the `obaas` user:

```bash
cd ~/obaas
source ./activate.env
ansible-playbook ~/obaas/ansible/images_build.yaml
```

After the images are built and pushed, the port-forward is no longer required and can be stopped.

### Deploy Microservices

Assuming the source was unzipped to `~/obaas`, run this command as the `obaas` user:

```bash
cd ~/obaas
source ./activate.env
ansible-playbook ~/obaas/ansible/k8s_apply.yaml -t full
```

## Notes

### config-server and obaas-admin Pod Failures

The Pods in the `config-server` and `obaas-admin` namespaces rely on the database that is created in
the `oracle-database-operator-system`. During the initial provisioning, these Pods start well before the database is available resulting in initial failures. They resolve themselves once the database becomes available.

You can check on the status of the database by running this command:

`kubectl get singleinstancedatabase baas -n oracle-database-operator-system -o "jsonpath={.status.status}"`

### VPN and Proxies

If you are behind a Virtual Private Network (VPN) or proxy, see https://minikube.sigs.k8s.io/docs/handbook/vpn_and_proxy/ for more details on additional tasks.

Next, go to the [Getting Started](../getting-started/) page to learn more.
