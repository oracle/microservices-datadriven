# On-Premises Installation - MacOS Ventura (x86)

This is an example of installing on a MacOS Venture desktop

Please read the [On-Premises](../index.md) and ensure your desktop meets the minimum system requirements.

## Install

### Podman

```bash
brew install podman
PODMAN_VERSION=$(podman -v |awk '{print $NF}')
sudo /usr/local/Cellar/podman/${PODMAN_VERSION}/bin/podman-mac-helper install
podman machine init --cpus 4 --disk-size 60 --memory 8192 --rootful --now
podman system connection default podman-machine-default-root
```

### Download the Database/ORDS Images

The _Desktop_ installation will provision an Oracle Database into the Kubernetes cluster.  The images must be downloaded from [Oracle's Container Registry](https://container-registry.oracle.com/) prior to continuing.

1. Log into Oracle's Container Registry: `podman login container-registry.oracle.com`
2. Pull the Database Image: `podman pull container-registry.oracle.com/database/enterprise:21.3.0.0`
3. Pull the ORDS Image: `podman pull container-registry.oracle.com/database/ords:21.4.2-gh`

### Minikube

```bash
brew install minikube
minikube config set driver podman
minikube start --cpus 4 --memory max --container-runtime=containerd
minikube addons enable ingress
```

If minikube fails to start due to: `Failed kubeconfig update: could not read config`, run: `mv ~/.kube ~/.kube.bak` and retry.

### Download Oracle Backend for Spring Boot

Download the [Oracle Backend for Spring Boot](https://github.com/oracle/microservices-datadriven/releases/download/OBAAS-1.0.0/onprem-ebaas-platform_latest.zip) and unzip into a new directory.

### Install Ansible

```bash
./setup_ansible.sh
source ./activate.env
```

### Define the Infrastructure

Use the helper Playbook to define the infrastructure.  This Playbook will also:

* Create additional namespaces for the Container Registry and Database
* Create a Private Container Registry in the Kubernetes Cluster
* Modify the application microservices to be Desktop compatible

Run: `ansible-playbook ansible/desktop_apply.yaml`

### Open a Tunnel

In order to push the images to the Container Registry in the Kubernetes cluster; open a new terminal and start a tunnel.

Run: `minikube tunnel`

To test access to the registry:
`curl -X GET -k https://localhost:5000/v2/_catalog`

The above curl should result in:

```text
{"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":[{"Type":"registry","Class":"","Name":"catalog","Action":"*"}]}]}
```

### Build the Images

Build and Push the Images to the Container Registry in the Kubernetes cluster:

Run: `ansible-playbook ansible/images_build.yaml`

After the images are built and pushed, the tunnel is no longer required and can be stopped.

### Deploy Oracle Backend for Spring Boot

Deploy the Database and Microservices.

Run: `ansible-playbook ansible/k8s_apply.yaml -t full`

## Notes

## VPN and Proxies

If you are behind a VPN or Proxy, please see https://minikube.sigs.k8s.io/docs/handbook/vpn_and_proxy/ for more details on additional tasks.