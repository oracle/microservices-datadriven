# On-Premises Installation - Oracle Linux 8 (x86)

This is an example of installing on a Oracle Linux 8 desktop.

Read the [On-Premises](../../on-premises) documentation and ensure that your desktop meets the minimum system requirements.

## Install

### Additional Operating System Packages

Install additional operating system packages by executing these commands:

```bash
sudo dnf -y module install container-tools:ol8
sudo dnf -y install conntrack podman curl
sudo dnf -y install oracle-database-preinstall-21c
sudo dnf -y install langpacks-en
sudo dnf module install python39
```

Set the default Python3 to Python 3.9:

```bash
sudo alternatives --set python3 /usr/bin/python3.9
```

### Create a Non-Root User

Create a new user.  While any username can be created, the rest of the documentation will refer to the non-root user as `obaas`:

As `root`:

```bash
useradd obaas
echo "obaas ALL=(ALL) NOPASSWD: /bin/podman" >> /etc/sudoers
```

### Download the Database/ORDS Images

The _Desktop_ installation will provision an Oracle Database into the Kubernetes cluster.  The images must be downloaded from [Oracle's Container Registry](https://container-registry.oracle.com/) prior to continuing.

As the `obaas` user:

1. Log into Oracle's Container Registry: `podman login container-registry.oracle.com`
2. Pull the Database Image: `podman pull container-registry.oracle.com/database/enterprise:19.19.0.0`
3. Pull the ORDS Image: `podman pull container-registry.oracle.com/database/ords:21.4.2-gh`

### Install and Start Minikube

As the `root` user:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
```

As the `obaas` user:

```bash
echo "PATH=\$PATH:/usr/sbin" >> ~/.bashrc
minikube config set driver podman
minikube start --cpus max --memory 7900mb --disk-size='40g' --container-runtime=cri-o
minikube addons enable ingress
```

### Download Oracle Backend for Spring Boot

As the `obaas` user:

Download the [Oracle Backend forSpring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/onprem-ebaas_latest.zip) and unzip into a new directory; example:

```bash
unzip onprem-ebaas_latest.zip -d ~/obaas
```

### Install Ansible

As the `obaas` user, change to the source directory and install ansible:

```bash
cd ~/obaas
./setup_ansible.sh
source ./activate.env
```

### Define the Infrastructure

Use the helper Playbook to define the infrastructure.  This Playbook will also:

* Create additional namespaces for the Container Registry and Database
* Create a Private Container Registry in the Kubernetes Cluster
* Modify the application microservices to be Desktop compatible


Assuming the source was unzip'ed to `~/obaas`, as the `obaas` user, run: `ansible-playbook ~/obaas/ansible/desktop_apply.yaml`

### Open a Tunnel

In order to push the images to the Container Registry in the Kubernetes cluster; open a new terminal and start a port-forward.

As the `obaas` user, run: `kubectl port-forward service/private -n container-registry 5000:5000 &`

To test access to the registry:
`curl -X GET -k https://localhost:5000/v2/_catalog`

The above curl should result in:

```text
{"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":[{"Type":"registry","Class":"","Name":"catalog","Action":"*"}]}]}
```

### Build the Images

Build and Push the Images to the Container Registry in the Kubernetes cluster:

Assuming the source was unzip'ed to `~/obaas`, as the `obaas` user, run: `ansible-playbook ~/obaas/ansible/images_build.yaml`

After the images are built and pushed, the port-forward is no longer required and can be stopped.

### Deploy Microservices

Assuming the source was unzip'ed to `~/obaas`, as the `obaas` user, run: `ansible-playbook ~/obaas/ansible/k8s_apply.yaml -t full`

## Notes

## config-server and obaas-admin Pod Failures

The pods in the `config-server` and `obaas-admin` namespaces rely on the database that is created in the `oracle-database-operator-system`.  During initial provisioning these pods will start well before the database is available resulting in initial failures.  They will resolve themselves once the database becomes available.

You can check on the status of the database by running:
`kubectl get singleinstancedatabase baas -n oracle-database-operator-system -o "jsonpath={.status.status}"`

### VPN and Proxies

If you are behind a VPN or Proxy, please see https://minikube.sigs.k8s.io/docs/handbook/vpn_and_proxy/ for more details on additional tasks.
