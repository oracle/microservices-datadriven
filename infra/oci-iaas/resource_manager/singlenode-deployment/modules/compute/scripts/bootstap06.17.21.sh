#!/bin/bash

# Variables
USER_NAME=opc
USER_HOME=/home/${USER_NAME}
APP_NAME=oci-grabdish
DEV_TOOLS_HOME=${USER_HOME}/${APP_NAME}
APP_CONFIG_FILE_NAME=config-${APP_NAME}.json
INSTALL_LOG_FILE_NAME=install-${APP_NAME}.log
INSTALL_LOG_FILE=${USER_HOME}/${INSTALL_LOG_FILE_NAME}
APP_CONFIG_FILE=${USER_HOME}/${APP_CONFIG_FILE_NAME}
SSHD_BANNER_FILE=/etc/ssh/sshd-banner
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
UPDATE_SCRIPT_FILE=update-kit.sh
UPDATE_SCRIPT_WITH_PATH=/usr/local/bin/${UPDATE_SCRIPT_FILE}
UPDATE_SCRIPT_LOG_FILE=${USER_HOME}/${UPDATE_SCRIPT_FILE}.log
CURL_METADATA_COMMAND="curl -L http://169.254.169.254/opc/v1/instance/metadata"


INSTALLATION_IN_PROGRESS="
    #################################################################################################
    #                                           WARNING!                                            #
    #   OCI Development Kit Installation is still in progress.                                      #
    #   To check the progress of the installation run -> tail -f ${INSTALL_LOG_FILE_NAME}           #
    #################################################################################################
"

USAGE_INFO="
    =================================================================================================
                                        OCI DEV KIT Usage
                                        ===================
    This instance has OCI Dev Kit such as CLI, Terraform, Ansible, SDKs (Java, Python3.6, Go, Dotnet, Ruby, Typescript)

    To update OCI Dev Kit to the latest version, run the following command: ${UPDATE_SCRIPT_FILE}

    You could use Instance Principal authentication to use the dev tools.

    For running CLI, type the following to get more help: oci --help
    =================================================================================================
"

start=`date +%s`

# create a configuration file

# Config file
sudo -u ${USER_NAME} touch ${APP_CONFIG_FILE}

cat >.${APP_CONFIG_FILE} <<EOF
    {
      "wifi": {
          "ssid": "Test1",
          "pw":   "Test2"
      }
    grabdish_application_password = $(oci-metadata -g grabdish_application_password --value-only)
    grabdish_database_password = $(oci-metadata -g grabdish_database_password --value-only)
    app_public_repo = $(oci-metadata -g app_public_repo --value-only)
    iaas_public_repo = $(oci-metadata -g iaas_public_repo --value-only)
    dbaas_FQDN =  $(oci-metadata -g dbaas_FQDN --value-only)
    }
EOF

#for Grabdish Compute Base Image
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum-config-manager --enable ol8_developer  --enablerepo ol8_developer_EPEL
sudo dnf -y update
sudo yum install -y python36
sudo yum install -y oci-ansible-collection
sudo python -m pip install oci oci-cli
sudo dnf module install -y go-toolset
sudo yum install -y jdk-16.0.1.0.1.x86_64
sudo yum install -y git
sudo dnf install -y gnupg2 curl tar
sudo dnf install -y @ruby
sudo dnf install -y @nodejs:14
#sudo dnf install -y oracle-instantclient-release-el8 oraclelinux-developer-release-el8
sudo dnf install -y node-oracledb-node14
sudo yum install -y oci-dotnet-sdk
sudo yum -y install maven
#sudo dnf install -y oracle-database-preinstall-19c
sudo yum install -y libnsl
sudo yum remove -y oracle-instantclient-basic libclntsh

sudo rpm -i https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.11-basic-19.11.0.0.0-1.x86_64.rpm
sudo rpm -i https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.11-sqlplus-19.11.0.0.0-1.x86_64.rpm
sudo rpm -i https://yum.oracle.com/repo/OracleLinux/OL8/oracle/instantclient/x86_64/getPackage/oracle-instantclient19.11-tools-19.11.0.0.0-1.x86_64.rpm

curl -sL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-20.1.0/graalvm-ce-java11-linux-amd64-20.1.0.tar.gz | tar xz
  ~/graalvm-ce-java11-20.1.0/bin/gu install native-image


#Post Provisioning
sudo rpm -i  https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm

sudo yum-config-manager     --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce docker-ce-cli
sudo systemctl enable docker
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock

sudo yum -y install conntrack

sudo systemctl stop firewalld
sudo service firewalld stop

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker


#minikube start --driver=none
#versus
sudo systemctl restart docker
minikube start --driver=docker
minikube addons enable ingress


curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

sudo cp -r /home/opc/.minikube /home/oracle/.
sudo chown -R  oracle:oinstall /home/oracle/.minikube

sudo mkdir -p /home/oracle/.kube
sudo cp /home/opc/.kube/config /home/oracle/.kube/.
sudo sed -i "s|/home/opc/|/home/oracle/|g" /home/oracle/.kube/config
sudo chown -R oracle:oinstall /home/oracle/.kube

minikube stop


---------------
#Post Provisioning
sudo systemctl enable docker
sudo systemctl start docker
minikube start
minikube addons enable ingress
docker run -d   -p 5000:5000   --restart=always   --name registry   registry:2






# yum install packages are listed here. This same list is used for update too
PACKAGES_TO_INSTALL=(
    python36-oci-cli 
    terraform 
      terraform-provider-oci
    oci-ansible-collection 
    python36-oci-sdk.x86_64 
    oracle-golang-release-el7
    golang 
    go-oci-sdk 
    java-oci-sdk
    git-1.8.3.1-23.el7_8.x86_64
    rh-ruby27
    oci-ruby-sdk
    oracle-nodejs-release-el7
    oci-dotnet-sdk.noarch
    oci-powershell-modules
)

# Log file
sudo -u ${USER_NAME} touch ${INSTALL_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${INSTALL_LOG_FILE}

# Sending all stdout and stderr to log file
exec >> ${INSTALL_LOG_FILE}
exec 2>&1

echo "Installing OCI Dev Kit"
echo "------------------------"

echo "Creating sshd banner"
sudo touch ${SSHD_BANNER_FILE}
sudo echo "${INSTALLATION_IN_PROGRESS}" > ${SSHD_BANNER_FILE}
sudo echo "${USAGE_INFO}" >> ${SSHD_BANNER_FILE}
sudo echo "Banner ${SSHD_BANNER_FILE}" >> ${SSHD_CONFIG_FILE}
sudo systemctl restart sshd.service

####### Installing yum packages #########

echo "Packages to install ${PACKAGES_TO_INSTALL[@]}"

sudo yum-config-manager --enable ol7_developer ol7_developer_EPEL && echo "#################### Successfully installed ol7_developer yum packages #####################"

echo "Manually Disabling MYSQL"
sudo yum --disablerepo=ol7_MySQL80 update

sudo yum -y install ${PACKAGES_TO_INSTALL[@]} && echo "#################### Successfully installed all yum packages #####################"

sudo yum -y install --enablerepo=ol7_developer_nodejs10 --enablerepo=ol7_developer oci-typescript-sdk && echo "#################### Successfully installed typescript #####################"

####### Installing yum packages -End #########

####### Adding OCI Modules to Powershell #########

sudo -u ${USER_NAME} pwsh -c Register-PSRepository -Name LocalRepository -SourceLocation /usr/lib/dotnet/NuPkgs -InstallationPolicy Trusted
sudo -u ${USER_NAME} pwsh -c "Set-Variable -Name ProgressPreference -Value SilentlyContinue; Install-Module OCI.PSModules -Repository LocalRepository"
sudo -u ${USER_NAME} pwsh -c Uninstall-Module OCI.PSModules
sudo -u ${USER_NAME} pwsh -c Unregister-PSRepository -Name LocalRepository

####### Adding OCI Modules to Powershell -End #########

####### Adding environment variables #########
echo "Adding environment variable so terraform can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export TF_VAR_auth=InstancePrincipal' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_region=$(oci-metadata -g regionIdentifier --value-only)" >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_tenancy_ocid=$(oci-metadata -g tenancy_id --value-only)" >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export OCI_CLI_AUTH=instance_principal' >> ${USER_HOME}/.bashrc

echo "Adding environment variable so ansible can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export OCI_ANSIBLE_AUTH_TYPE=instance_principal' >> ${USER_HOME}/.bashrc

echo "Adding environment variable so powershell can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export OCI_PS_AUTH="InstancePrincipal"' >> ${USER_HOME}/.bashrc

sudo -u ${USER_NAME} echo 'export GOPATH=/usr/share/gocode' >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci jars are in the classpath"
JAVASDK_VERSION=$(yum list java-oci-sdk | grep -o "[0-9].[0-9]\+.[0-9]\+" | head -1)
sudo -u ${USER_NAME} echo "export CLASSPATH=/usr/lib64/java-oci-sdk/lib/oci-java-sdk-full-${JAVASDK_VERSION}.jar:/usr/lib64/java-oci-sdk/third-party/lib/*" >> ${USER_HOME}/.bashrc

echo "Adding environment variable so ruby collections are properly set"
sudo -u ${USER_NAME} echo "source scl_source enable rh-ruby27" >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export GEM_PATH=/usr/share/gems:'gem env gempath'" >> ${USER_HOME}/.bashrc
echo "Adding environment variable so dotnet collections are properly set"
sudo -u  ${USER_NAME} echo "source scl_source enable rh-dotnet31" >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo echo 'export OCI_CLI_AUTH=instance_principal' >> /etc/bashrc

echo "Adding environment variable for SDK analytics"
sudo -u ${USER_NAME} echo 'export OCI_SDK_APPEND_USER_AGENT=Oracle-ORMDevTools' >> ${USER_HOME}/.bashrc

####### Adding environment variables - End #########

####### Generating upgrade script #########
DOLLAR_SIGN="$"

echo "Creating update script"
echo "----------------------"
cat > ${UPDATE_SCRIPT_WITH_PATH} <<EOL
#!/bin/bash

PACKAGES_TO_UPDATE=(
    python36-oci-cli 
    terraform 
    terraform-provider-oci 
    oci-ansible-collection 
    python36-oci-sdk.x86_64 
    oracle-golang-release-el7
    golang 
    go-oci-sdk 
    java-oci-sdk
    git
    oci-ruby-sdk
    oracle-nodejs-release-el7
    --enablerepo=ol7_developer_nodejs10 --enablerepo=ol7_developer oci-typescript-sdk
    oci-dotnet-sdk.noarch
    oci-powershell-modules
)

# Log file
sudo -u ${USER_NAME} touch ${UPDATE_SCRIPT_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${UPDATE_SCRIPT_LOG_FILE}

exec > >(tee ${UPDATE_SCRIPT_LOG_FILE})
exec 2>&1

echo "Updating OCI Dev Kit"
echo "----------------------"

echo "Packages to update ${DOLLAR_SIGN}{PACKAGES_TO_UPDATE[@]}"
sudo yum -y install ${DOLLAR_SIGN}{PACKAGES_TO_UPDATE[@]} && echo "#################### Successfully updated all yum packages #####################"

echo "-----------------------------------"
echo "Updating OCI Dev Kit is complete"

EOL
####### Generating upgrade script -End #########
echo "Update script creation complete"

sudo chmod +x ${UPDATE_SCRIPT_WITH_PATH}

sudo -u ${USER_NAME} touch ${APP_CONFIG_FILE}

cat >${APP_CONFIG_FILE} <<EOF
{
    "grabdish_application_password":  "$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq --raw-output '.grabdish_application_password')",
    "grabdish_database_password":  "$($CURL_METADATA_COMMAND | jq --raw-output  '.grabdish_database_password')",
    "app_public_repo":  "$($CURL_METADATA_COMMAND | jq --raw-output  '.app_public_repo')",
    "iaas_public_repo":  "$($CURL_METADATA_COMMAND | jq --raw-output  '.iaas_public_repo')",
    "dbaas_FQDN":   "$($CURL_METADATA_COMMAND | jq --raw-output  '.dbaas_FQDN')"
}
EOF


end=`date +%s`

executionTime=$((end-start))

echo "--------------------------------------------------------------"
echo "Installation of OCI Dev Kit is complete. (Took ${executionTime} seconds)"

sudo echo "${USAGE_INFO}" > ${SSHD_BANNER_FILE}

exec -l $SHELL


curl -L http://169.254.169.254/opc/v1/instance/metadata | jq --raw-output '.grabdish_database_password_password')",
    "grabdish_database_password":  "$($CURL_METADATA_COMMAND | jq --raw-output  '.grabdish_database_passwor



#  344  minikube delete
#  345  minikube start --driver=none
#  346  docker container stop registry
#  347  docker container rm registry
#  348  docker run -d   -p 5000:5000   --restart=always   --name registry   registry:2

#docker run -d   --restart=always   --name registry   -v "$(pwd)"/certs:/certs   -e REGISTRY_HTTP_ADDR=0.0.0.0:443   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt   -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key   -p 443:443   registry:2
#docker container stop registry
#docker container rm registry



#  344  minikube delete
#  345  minikube start --driver=none
#  346  docker container stop registry
#  347  docker container rm registry
#  348  docker run -d   -p 5000:5000   --restart=always   --name registry   registry:2

#docker run -d   --restart=always   --name registry   -v "$(pwd)"/certs:/certs   -e REGISTRY_HTTP_ADDR=0.0.0.0:443   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt   -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key   -p 443:443   registry:2
#docker container stop registry
#docker container rm registry



$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_ns_msdataworkshop.sh
$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_frontendpasswd.sh
$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_dbpasswd.sh
$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_dbwallet.sh
$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_ssl-certificate-secret.sh


docker run --name microservice-database3 -p 1521:1521 -p 5500:5500 --user 54321:54321 --hostname grabdish_docker-db1 -e ORACLE_SID=orcl -e ORACLE_PDB=orcl_pdb -e ORACLE_PWD=Welcome123 -e ORACLE_EDITION=enterprise   -v /opt/oracle/oradata dbcs-dev-docker.dockerhub-phx.oci.oraclecorp.com/oracle/database:RDBMS_21.3.0.0.0_LINUX.X64_210709



System parameter file is /opt/oracle/homes/OraDB21Home1/network/admin/listener.ora
Log messages written to /opt/oracle/diag/tnslsnr/ffa6a4004a14/listener/alert/log.xml
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1)))
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=0.0.0.0)(PORT=1521)))

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=EXTPROC1)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 21.0.0.0.0 - Production
Start Date                06-AUG-2021 19:20:14
Uptime                    0 days 0 hr. 0 min. 0 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /opt/oracle/homes/OraDB21Home1/network/admin/listener.ora
Listener Log File         /opt/oracle/diag/tnslsnr/ffa6a4004a14/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=0.0.0.0)(PORT=1521)))
The listener supports no services
The command completed successfully



docker run --name [container name]
-p [host port]:1521 -p :5500
-e ORACLE_SID=[your SID]
-e ORACLE_PDB=[your PDB name]
-e ORACLE_PWD=[your database passwords]
-e INIT_SGA_SIZE=[your database SGA memory in MB]
-e INIT_PGA_SIZE=[your database PGA memory in MB]
-e ORACLE_EDITION=[your database edition]
-e ORACLE_CHARACTERSET=[your character set]
-v [host mount point:]/opt/oracle/oradata
dbcs-dev-docker.dockerhub-phx.oci.oraclecorp.com/oracle/database:17754

Parameters:
   --name:        The name of the container (default: auto generated)
   -p:            The port mapping of the host port to the container port.
                  Two ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express)
   -e ORACLE_SID: The Oracle Database SID that should be used (default: ORCLCDB)
   -e ORACLE_PDB: The Oracle Database PDB name that should be used (default: ORCLPDB1)
   -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated)
   -e INIT_SGA_SIZE:
                  The total memory in MB that should be used for all SGA components (optional).
   -e INIT_PGA_SIZE:
                  The target aggregate PGA memory in MB that should be used for all server processes attached to the instance (optional).
   -e ORACLE_EDITION:
                  The Oracle Database Edition (enterprise/standard).
   -e ORACLE_CHARACTERSET:
                  The character set to use when creating the database (default: AL32UTF8)
   -v /opt/oracle/oradata
                  The data volume to use for the database.
                  Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
                  If omitted the database will not be persisted over container recreation.
   -v /opt/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup
                  Optional: A volume with custom scripts to be run after database startup.
   -v /opt/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup
                  Optional: A volume with custom scripts to be run after database setup.


docker run --name db-19300-docker -p 1


docker run --name microservice-database -p 1521:1521 -p 5500:5500 --user 54321:54321 --hostname grabdish_docker-db1 -e ORACLE_SID=orcl -e ORACLE_PDB=orcl_pdb -e ORACLE_PWD=Welcome123 -e ORACLE_EDITION=enterprise   -v /opt/oracle/oradata -v /opt/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup -v /opt/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup dbcs-dev-docker.dockerhub-phx.oci.oraclecorp.com/oracle/database:17754

docker run --name microservice-database -p 1521:1521 -p 5500:5500 --user 54321:54321 --hostname grabdish_docker-db1 -e ORACLE_SID=orcl -e ORACLE_PDB=orcl_pdb -e ORACLE_PWD=Welcome123 -e ORACLE_EDITION=enterprise   -v /opt/oracle/oradata container-registry.oracle.com/database/enterprise:latest



[oracle@grabdish_docker-db1 /]$ cp ~/tnsnames.ora /opt/oracle/oradata/dbconfig/ORCL/tnsnames.ora
[oracle@grabdish_docker-db1 /]$ cp ~/tnsnames.ora /opt/oracle/product/19c/dbhome_1/network/admin/tnsnames.ora