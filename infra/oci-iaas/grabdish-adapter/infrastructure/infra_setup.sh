#/bin/bash


install_dir=/software_install


sudo mkdir $install_dir
sudo chown opc:opc oracle:oinstall $install_dir
cd ${install_dir}
#sudo yum-config-manager --enable ol7_addons
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -Uvh minikube-latest.x86_64.rpm
sudo yum-config-manager     --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce docker-ce-cli
#sudo yum install docker-engine docker-cli
sudo systemctl enable docker
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock
sudo yum -y install conntrack

minikube start --driver=none
minikube addons enable ingress

docker run -d   -p 5000:5000   --restart=always   --name registry   registry:2
sudo yum -y install maven
sudo yum -y install git

curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

#mkdir /software_install
#cd /software_install
git clone -b 1.4 --single-branch https://github.com/oracle/microservices-datadriven.git
sudo chmod 777 -R ${install_dir}



sudo mkdir ~oracle/.kube
sudo cp ~opc/.kube/config ~oracle/.kube/config
sudo chown -R oracle:oinstall ~oracle/.kube
#sed replace minikube cert infor

sudo cp -r ~opc/.minikube ~oracle/.
sudo chown -R oracle:oinstall ~oracle/.minikube

state_set DOCKER_REGISTRY localhost:5000

state_set_done JAVA_REPOS


sudo su - oracle
#update .bashrc
export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin

pushd .
source ${install_dir}/microservices-datadriven/grabdish/env.sh 
popd 

