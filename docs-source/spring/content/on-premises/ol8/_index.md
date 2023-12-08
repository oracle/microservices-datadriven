---
title: "On-Premises Installation - Oracle Linux 8 (x86)"
---

This is an description of installing on a Oracle Linux 8 desktop.

Read the [On-Premises](../../on-premises) documentation and ensure that your desktop meets the minimum system requirements.

## Install

### Additional Operating System Packages

Install additional operating system packages by executing these commands:

```bash
dnf -y module install container-tools:ol8
dnf -y install conntrack podman podman-docker curl libcgroup
dnf -y install oracle-database-preinstall-21c
dnf -y install langpacks-en shadow-utils
dnf module install -y python39
dnf -y upgrade
```

Set the default Python3 to Python 3.9 by running this command:

```bash
sudo alternatives --set python3 /usr/bin/python3.9
```

### Enable Control Groups Version 2

In order to run in root-less mode, enable cgroup-v2:

Create directories for systemd:

```bash
mkdir -p /etc/systemd/system/user@.service.d/
mkdir -p /etc/systemd/system/user-.slice.d/
```

Create the cgroup systemd files:

```bash
cat > /etc/systemd/system/user@.service.d/delegate.conf << EOF
[Service]
Delegate=cpu cpuset io memory pids
EOF

cat > /etc/systemd/system/user-.slice.d/override.conf << EOF
[Slice]
Slice=user.slice

CPUAccounting=yes
MemoryAccounting=yes
IOAccounting=yes
TasksAccounting=yes
EOF

cat > /etc/systemd/system/user-0.slice << EOF
[Unit]
Before=systemd-logind.service
[Slice]
Slice=user.slice
[Install]
WantedBy=multi-user.target
EOF
```

Enable cgroup-v2 and reboot:

```bash
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"
reboot
```

### Install Minikube

As the `root` user, install Minikube:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
```

### Create a Non-Root User

Create a new user. While any user name can be created, the rest of this documentation refers to the non-root user as `obaas`:

As `root`, process the following:

```bash
useradd obaas
```

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
echo "PATH=\$PATH:/usr/sbin" >> ~/.bashrc
minikube config set rootless true
minikube config set driver podman
minikube start --cpus max --memory 7900mb --disk-size='40g' --container-runtime=containerd
minikube addons enable ingress
```

### Download Oracle Backend for Spring Boot and Microservices

Download [Oracle Backend for Spring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/onprem-ebaas_latest.zip) and unzip into a new directory.

While directly logged into the `obaas` user, run these commands:

```bash
unzip onprem-ebaas_latest.zip -d ~/obaas
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
kubectl port-forward service/private -n container-registry 5000:5000  > /dev/null 2>&1 &`
```

### Build the Images

Build and push the images to the Container Registry in the Kubernetes cluster.

Assuming the source was unzipped to `~/obaas`, run the following command as the `obaas` user:

```bash
cd ~/obaas
source ./activate.env
ansible-playbook ~/obaas/ansible/images_build.yaml`
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
