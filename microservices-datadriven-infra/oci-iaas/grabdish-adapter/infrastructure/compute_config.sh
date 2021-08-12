#/bin/bash


install_dir=/software_install

cd ${install_dir}
#sudo rpm -Uvh minikube-latest.x86_64.rpm


sudo systemctl stop firewalld
sudo systemctl disable firewalld

sudo systemctl enable docker
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

minikube start --driver=none
minikube addons enable ingress

docker run -d   -p 5000:5000   --restart=always   --name registry   registry:2

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

sudo mkdir ~oracle/.kube
sudo cp ~opc/.kube/config ~oracle/.kube/config
sudo chown -R oracle:oinstall ~oracle/.kube
#sed replace minikube cert infor

sudo cp -r ~opc/.minikube ~oracle/.
sudo chown -R oracle:oinstall ~oracle/.minikube

state_set DOCKER_REGISTRY localhost:5000

state_set_done JAVA_REPOS


#sudo su - oracle
#update .bashrc
#export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
#export PATH=$PATH:$ORACLE_HOME/bin

#pushd .
#source ${install_dir}/microservices-datadriven/grabdish/env.sh 
#popd 

