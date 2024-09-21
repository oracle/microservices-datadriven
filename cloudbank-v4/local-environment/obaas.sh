#!/bin/bash

echo "This script will start up Oracle Backend for Oracle Backend for Microservices and AI in a local container"
echo "Not recommended for machines with less than 64GB RAM"

echo "Create network (ignore failure if already exists)"
docker network create --subnet 172.98.0.0/16 obaasnw

echo "Start the cluster"
docker run -d \
  --privileged \
  --name obaas \
  -e K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml \
  -e K3S_KUBECONFIG_MODE=666 \
  -v $(pwd)/k3s_data/kubeconfig:/output \
  -v $(pwd)/k3s_data/rancher:/etc/rancher \
  -v $(pwd)/k3s_data/manifests:/var/lib/rancher/k3s/server/manifests/addons \
  -v $(pwd)/image_archive:/image_archive \
  --ulimit nproc=65535 \
  --ulimit nofile=65535:65535 \
  -p 6443:6443 \
  -p 80 \
  -p 443 \
  --restart=always \
  --network=obaasnw \
  rancher/k3s:v1.30.4-rc1-k3s1-amd64 \
  server

echo "Create DB startup-scripts PV and populate it" 
docker exec -ti obaas mkdir -p /var/lib/rancher/k3s/storage/startup-scripts/startup
docker cp ./txeventq-privs.sql obaas:/var/lib/rancher/k3s/storage/startup-scripts/startup/txevent-privs.sql 

echo "Import images (first time will download them, and will wait a few seconds for cluster to be up)"
if [ ! -f $(pwd)/image_archive/images.tar ]; then
  wget -O $(pwd)/image_archive/images.tar https://bit.ly/obaas-image-archive
fi
sleep 10
docker exec -ti obaas ctr images import /image_archive/images.tar

echo 'Watch progress using this command:'
echo 'watch KUBECONFIG=$(pwd)/k3s_data/kubeconfig/kubeconfig.yaml kubectl get pod -A'
