#!/bin/bash

# Variables
USER_NAME=opc
USER_HOME=/home/${USER_NAME}
DBUSER_NAME=oracle
DBUSER_HOME=/home/${DBUSER_NAME}
APP_NAME=infra
APP_CONFIG_FILE_NAME=${APP_NAME}-config.json
INSTALL_LOG_FILE_NAME=${APP_NAME}-install.log
INSTALL_LOG_FILE=${USER_HOME}/${INSTALL_LOG_FILE_NAME}
APP_CONFIG_FILE=${USER_HOME}/${APP_CONFIG_FILE_NAME}
BUILD_LOG_FILE=${USER_HOME}/${APP_NAME}-build

#INSTALL_ROOT_DIR=/microservices
INSTALL_ROOT_DIR=${USER_HOME}
APP_INSTALL_DIR=${INSTALL_ROOT_DIR}/microservices-datadriven
INFRA_INSTALL_DIR=${INSTALL_ROOT_DIR}/microservices-datadriven/${APP_NAME}
INFRA_HOME=${INSTALL_ROOT_DIR}/microservices-datadriven/${APP_NAME}
TNS_ADMIN_LOC=${INFRA_HOME}/oci-iaas/grabdish-adapter/database/TNS_ADMIN
DOCKER_CERTS_DIR=${INFRA_INSTALL_DIR}/oci-iaas/grabdish-adapter/infrastructure

SSHD_BANNER_FILE=/etc/ssh/sshd-banner
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
CURL_METADATA_COMMAND="curl -L http://169.254.169.254/opc/v1/instance/metadata"
TEMP_DIR=/grabdish_tmp
PWD=$(dirname "$0")
#ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
ORACLE_HOME="/usr/lib/oracle/19.11/client64"  # For Oracle 19c client


INSTALLATION_IN_PROGRESS="
    #################################################################################################
    #                                           WARNING!                                            #
    #   Microservices Data-driven Infrastructure Build  is still in progress.                                      #
    #   To check the progress of the installation run -> tail -f ${INSTALL_LOG_FILE_NAME}           #
    #################################################################################################
"

USAGE_INFO="
    =================================================================================================
                                Microservices Data-driven Infrastructure
                            ================================================

    Microservices Data-driven Infrastructure is now available for usage

    For additional details regarding Microservices Data-driven applications on Oracle Converged Database check,

    https://github.com/oracle/microservices-datadriven

    =================================================================================================
"
DOCKER_REG_CMD="docker run -d \
  --restart=always \
  --name registry \
  -v "$DOCKER_CERTS_DIR"/certs:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -p 443:443 \
  registry:2"

declare -i print_header_count=0
declare -i print_subheader_count=0

function print_header (){
  print_header_count=$((print_header_count + 1))
  print_subheader_count=0
  echo ""
  echo "================================================================================"
  printf "\360\237\220\261 ${print_header_count}.: $1\n"
  echo "================================================================================"
  echo ""

  return
}

function print_subheader(){
 print_subheader_count=$((print_subheader_count + 1))
 printf "\360\237\246\204 ${print_header_count}.${print_subheader_count}.: [INFO]  $1\n"
 return
 }
 

start=$(date +%s)

# Log file
sudo -u ${USER_NAME} touch ${INSTALL_LOG_FILE} ${BUILD_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${INSTALL_LOG_FILE} ${BUILD_LOG_FILE}


# Sending all stdout and stderr to log file
exec >${INSTALL_LOG_FILE}
exec 2>&1


print_header "Starting Microservices Data-driven Infrastructure installation process at $(date)"

###########################################
# Create Microservices Data-driven Infrastructure Configuration File
###########################################
print_header "Creating Microservices Data-driven Infrastructure Configuration File." 

sudo -u ${USER_NAME} touch ${APP_CONFIG_FILE}

cat >${APP_CONFIG_FILE} <<EOF
{
    #"app_public_repo":        "$($CURL_METADATA_COMMAND | jq --raw-output '.app_public_repo')",
    #"iaas_public_repo":       "$($CURL_METADATA_COMMAND | jq --raw-output '.iaas_public_repo')",
    "iaas_app_public_repo":  "$($CURL_METADATA_COMMAND | jq --raw-output  '.iaas_app_public_repo')",
    "dbaas_FQDN":             "$($CURL_METADATA_COMMAND | jq --raw-output '.dbaas_FQDN')",
    "target_compartment_id":  "$($CURL_METADATA_COMMAND | jq --raw-output '.target_compartment_id')",
    "vcn_id":                 "$($CURL_METADATA_COMMAND | jq --raw-output '.vcn_id')",
    "subnet_id":              "$($CURL_METADATA_COMMAND | jq --raw-output '.subnet_id')",
    "image_os":               "$($CURL_METADATA_COMMAND | jq --raw-output '.image_os')",
    "image_os_version":       "$($CURL_METADATA_COMMAND | jq --raw-output '.image_os_version')",
    "instance_shape":         "$($CURL_METADATA_COMMAND | jq --raw-output '.instance_shape')"
}
EOF
print_subheader "Creation of Configuration Completed." 



##################################################
# Install Git and Telnet Packages
# yum install packages are listed here. This same list is used for update too
###################################################

print_header "Installing Git and Telnet Packages."

PACKAGES_TO_INSTALL=(
  git
  telnet
)

print_subheader "Packages to install ${PACKAGES_TO_INSTALL[@]}" 
sudo yum -y install ${PACKAGES_TO_INSTALL[@]} && print_subheader "Successfully installed all yum packages" 
print_subheader "Required Packages Installed."



print_header "Creating sshd banner"
sudo touch ${SSHD_BANNER_FILE} 
sudo bash -c "echo "${INSTALLATION_IN_PROGRESS}" >${SSHD_BANNER_FILE}"
sudo bash -c "echo "${USAGE_INFO}" >>${SSHD_BANNER_FILE}"
sudo bash -c "echo "Banner ${SSHD_BANNER_FILE}" >>${SSHD_CONFIG_FILE}"
print_subheader "SSHD Banner created"
sudo systemctl restart sshd.service | 
print_subheader "Restarted SSHD Service"

####### Adding environment variables #########
print_header "Creating Environment Variables"
print_subheader "Adding environment variable so terraform can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export TF_VAR_auth=InstancePrincipal' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_region=$(oci-metadata -g regionIdentifier --value-only)" >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_tenancy_ocid=$(oci-metadata -g tenancy_id --value-only)" >> ${USER_HOME}/.bashrc

print_subheader "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export OCI_CLI_AUTH=instance_principal' >> ${USER_HOME}/.bashrc

print_subheader "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo echo 'export OCI_CLI_AUTH=instance_principal' >> /etc/bashrc

print_subheader "Adding Oracle Home and Path variables to bashrc"
sudo -u ${USER_NAME} echo "export ORACLE_HOME=${ORACLE_HOME}" >>${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TNS_ADMIN=${TNS_ADMIN_LOC}" >>${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export LD_LIBRARY_PATH="${ORACLE_HOME}"' >>${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export PATH="$ORACLE_HOME/bin:$PATH"' >>${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME/lib:$ORACLE_HOME' >>${USER_HOME}/.bashrc
print_subheader "Completed"

print_subheader "Adding APP_INSTALL_DIR and INFRA_INSTALL_DIR variables to bashrc"
sudo -u ${USER_NAME} echo export INFRA_INSTALL_DIR=${INFRA_HOME} >>${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo export INFRA_HOME=${INFRA_HOME} >>${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo export APP_INSTALL_DIR=${APP_INSTALL_DIR} >>${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "source <(kubectl completion bash)" >> ${USER_HOME}/.bashrc

sudo -u ${USER_NAME} echo 'source ${APP_INSTALL_DIR}/grabdish/env.sh' >>${USER_HOME}/.bashrc
print_subheader "Completed"

####### Adding environment variables - End #########



# Clone Application and Infrastructure Resource Files
print_header "Downloading Microservices Infrastructure and Application from public repositories"
#sudo mkdir -p $APP_INSTALL_DIR
#sudo mkdir -p $INFRA_INSTALL_DIR
#sudo chown -R opc:opc $APP_INSTALL_DIR $INFRA_INSTALL_DIR
#print_subheader "Created destination directories  $APP_INSTALL_DIR and $INFRA_INSTALL_DIR"

#sudo mkdir -p $INFRA_INSTALL_DIR
#sudo chown -R opc:opc $INFRA_INSTALL_DIR
#print_subheader "Created destination directory  $INFRA_INSTALL_DIR"


#app_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output '.app_public_repo')
#iaas_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output '.iaas_public_repo')
iaas_app_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output '.iaas_app_public_repo')


#print_subheader "Downloading Application code from $app_public_repo "
#sudo -u ${USER_NAME} $app_public_repo $APP_INSTALL_DIR

#print_subheader "Downloading Infrastructure code from $iaas_public_repo"
#sudo -u ${USER_NAME} $iaas_public_repo $INFRA_INSTALL_DIR

print_subheader "Downloading Infrastructure and Application code from ${iaas_app_public_repo}"
#sudo -u ${USER_NAME} ${iaas_app_public_repo} ${INSTALL_ROOT_DIR}
#sudo ${iaas_app_public_repo}

#sudo -u ${USER_NAME} ${iaas_app_public_repo}
sudo -u ${USER_NAME} bash -c "cd ${USER_HOME};${iaas_app_public_repo}"
#sudo chown -R opc:opc ${INSTALL_ROOT_DIR}
print_subheader "Downloaded Infrastructure and Application code"

sudo -u ${USER_NAME} mkdir -p $DOCKER_CERTS_DIR/certs
print_subheader "Granting read, write and execute permissions to users"
sudo chmod -R 777 $APP_INSTALL_DIR $INFRA_INSTALL_DIR
print_subheader "Completed"


######################################### TO DO ###########

# Infrastructure to Grabdish Application Bridge

print_header "Initialing Infrastructure to Grabdish Application Bridge"
#update tnsnames.ora
print_subheader "Updating TNS ORA  "
#sudo mkdir -p $TEMP_DIR
#sudo chown -R opc:opc $TEMP_DIR
#sudo chmod +rw $TEMP_DIR

print_subheader "Updating TNSNAMES and Listener ORA Files"
#sudo -u ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/database/update_tnsnames-ora.sh"
#sudo -u ${USER_NAME}  bash -c "cd ${INFRA_HOME}/oci-iaas/grabdish-adapter/database/; ./update_tnsnames-ora.sh"
sudo -u ${USER_NAME}  bash -c "${INFRA_HOME}/oci-iaas/grabdish-adapter/database/update_tnsnames-ora.sh ${TNS_ADMIN_DIR}"


#No Need for TEMP DIR -- refactor code later
sudo -u ${USER_NAME} cp $TEMP_DIR/*.ora ${TNS_ADMIN_LOC}/. 

print_subheader "Opening Firewall Port for HTTP/S, SQLNET Traffic"
sudo firewall-cmd --permanent --add-port=1521/tcp
sudo firewall-cmd --permanent --add-port=443/tcp 
sudo firewall-cmd --permanent --add-port=80/tcp 
sudo firewall-cmd --reload 
sudo firewall-cmd --list-all
print_subheader "Firewall Port opened"

print_header "Installing required infrastructure components"

sudo chmod 666 /var/run/docker.sock

print_subheader "Deleting previous installation of Minikube"
sudo su - ${USER_NAME} bash -c "minikube delete" 

print_subheader "Restarting Docker"
sudo systemctl restart docker 

print_subheader "Restarting Minikube cluster"
#sudo su - ${USER_NAME} bash -c "minikube start --driver=docker"  # encountering issue with https docker reg
sudo su - ${USER_NAME} bash -c "minikube start --driver=none"

print_subheader "Enabling Ingress on  K8 Cluster"
sudo su - ${USER_NAME} bash -c "minikube addons enable ingress" 

print_subheader "Starting Docker Registry"
sudo su - ${USER_NAME} bash -c "docker container stop registry && docker container rm -v registry" 
#sudo su - ${USER_NAME} bash -c "docker run -d   -p 5000:5000   --restart=always   --name registry   registry:2"  

print_subheader "Granting writing privilges to user ${USER_NAME}"
sudo chown -R opc:opc $DOCKER_CERTS_DIR

print_subheader "Creating SSL certificates for Docker Registry"
sudo su - ${USER_NAME} bash -c "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${DOCKER_CERTS_DIR}/certs/domain.key -out ${DOCKER_CERTS_DIR}/certs/domain.crt -subj \"/CN=grabdish/O=grabdish\""
#print_subheader "Created Docker Certificate"

#sudo su - ${USER_NAME} bash -c "cd$ DOCKER_CERTS_DIR;  $DOCKER_REG_CMD" # Docker Pull is failing
sudo su - ${USER_NAME} bash -c "docker run -d   -p 5000:5000   --restart=always   --name registry   registry:2"

print_header "Creating Secrets"
print_subheader "Creating namespace"
sudo su - ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_ns_msdataworkshop.sh"
print_subheader "Creating Secret frontendpasswd"
sudo su - ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_frontendpasswd.sh"
print_subheader "Creating Secret dbuser"
sudo su - ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_dbpasswd.sh"
print_subheader "Creating Secret dbwallet"
sudo su - ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_dbwallet.sh"
print_subheader "Creating Secret ssl-certificate-secret"
sudo su - ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_secret_ssl-certificate-secret.sh" 
print_subheader "Completed"

# These states are required for the Grabdish application build process to work
print_header "Creating States required for Grabdish Application"
print_subheader "These states are required for the Grabdish application build process to work"
sudo su - ${USER_NAME} bash -c "state_set_done OBJECT_STORE_BUCKET" 
sudo su - ${USER_NAME} bash -c "state_set_done ORDER_DB_OCID" 
sudo su - ${USER_NAME} bash -c "state_set_done INVENTORY_DB_OCID" 
sudo su - ${USER_NAME} bash -c "state_set_done WALLET_GET" 
sudo su - ${USER_NAME} bash -c "state_set_done CWALLET_SSO_OBJECT" 
sudo su - ${USER_NAME} bash -c "state_set_done DB_PASSWORD"
sudo su - ${USER_NAME} bash -c "state_set ORDER_DB_NAME orders" 
sudo su - ${USER_NAME} bash -c "state_set INVENTORY_DB_NAME inventory" 
#sudo su - ${USER_NAME} bash -c "state_set DOCKER_REGISTRY localhost:443"
sudo su - ${USER_NAME} bash -c "state_set DOCKER_REGISTRY localhost:5000"
print_subheader "Completed"


lab1_start=$(date +%s)

print_header "Building Lab 1"

print_subheader "Creating Jaeger Microservice"
sudo su - ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_service_jaeger.sh"
print_subheader "Started Jaeger Service"


print_subheader "Building frontend-helidon Microservice"
sudo su - ${USER_NAME} bash -c "cd ${APP_INSTALL_DIR}/grabdish/frontend-helidon;time ./build.sh > ${BUILD_LOG_FILE}-frontend-helidon.log;./deploy.sh "

print_subheader "Completed"

print_subheader "Creating Frontend Microservice"
sudo su - ${USER_NAME} bash -c "kubectl apply -n msdataworkshop -f $INFRA_HOME/oci-iaas/grabdish-adapter/k8s/frontend-service-nodeport.yaml"
print_subheader "Completed"

print_subheader "Creating Frontend Ingress"
sudo su - ${USER_NAME} bash -c "kubectl apply -n msdataworkshop -f $INFRA_HOME/oci-iaas/grabdish-adapter/k8s/frontend-ingress.yaml"
print_subheader "Completed"

MICROSERVICES="order-helidon supplier-helidon-se inventory-helidon"

print_subheader "Building ${MICROSERVICES}"

for service_name in $MICROSERVICES; do
  print_subheader "Creating Microservice ${service_name}"
  sudo su - ${USER_NAME} bash -c "cd ${APP_INSTALL_DIR}/grabdish/${service_name}; time ./build.sh>> ${BUILD_LOG_FILE}-${service_name}.log;./deploy.sh "
  print_subheader "${service_name} Completed"
  done

lab1_end=$(date +%s)

print_subheader "Lab 1 Build took $((lab1_end - lab1_start)) seconds"

end=$(date +%s) 

executionTime=$((end - start)) 


print_header "Provisioning Completed at $(date)"
print_header "Installation of Oracle Microservices Infrastructure and Data-driven Application is complete. Took ${executionTime} seconds"


#sudo echo "${USAGE_INFO}" >${SSHD_BANNER_FILE}



