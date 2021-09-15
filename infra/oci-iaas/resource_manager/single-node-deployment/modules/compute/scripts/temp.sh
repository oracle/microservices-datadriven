#!/bin/bash

# Variables
USER_NAME=opc
USER_HOME=/home/${USER_NAME}
DBUSER_NAME=oracle
DBUSER_HOME=/home/${DBUSER_NAME}
APP_NAME=microservices-infra
APP_CONFIG_FILE_NAME=${APP_NAME}-config.json
INSTALL_LOG_FILE_NAME=${APP_NAME}-install.log
INSTALL_LOG_FILE=${USER_HOME}/${INSTALL_LOG_FILE_NAME}
APP_CONFIG_FILE=${USER_HOME}/${APP_CONFIG_FILE_NAME}
BUILD_LOG_FILE=${USER_HOME}/${APP_NAME}-build

INSTALL_ROOT=/microservices
APP_INSTALL_DIR=$INSTALL_ROOT/microservices-datadriven
INFRA_INSTALL_DIR=${INSTALL_ROOT}/microservices-datadriven-infra
INFRA_HOME=${INSTALL_ROOT}/microservices-datadriven-infra
TNS_ADMIN_LOC=${INFRA_HOME}/oci-iaas/grabdish-adapter/database/TNS_ADMIN
DOCKER_CERTS_DIR=${INFRA_INSTALL_DIR}/oci-iaas/grabdish-adapter/infrastructure

SSHD_BANNER_FILE=/etc/ssh/sshd-banner
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
CURL_METADATA_COMMAND="curl -L http://169.254.169.254/opc/v1/instance/metadata"
TEMP_DIR=/grabdish_tmp
PWD=$(dirname "$0")
ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1



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
  echo "# ${print_header_count}.: $1"
  echo "================================================================================"
  echo ""

  return
}

function print_subheader(){
 print_subheader_count=$((print_subheader_count + 1))
 echo "#${print_header_count}.${print_subheader_count}.: [INFO]  $1"
 return
 }


# Sending all stdout and stderr to log file
exec >>${INSTALL_LOG_FILE}
exec 2>&1

start=$(date +%s)

# Log file

print_header "Building Lab 1"

print_subheader "Creating Jaeger Microservice"
sudo su - ${USER_NAME} bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/k8s/create_service_jaeger.sh"
print_subheader "Started Jaeger Service"


print_subheader "Building frontend-helidon Microservice"
sudo su - ${USER_NAME} bash -c "cd ${GRABDISH_HOME}/frontend-helidon;time ./build.sh > ${BUILD_LOG_FILE}-frontend-helidon.log;./deploy.sh "

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
  sudo su - ${USER_NAME} bash -c "cd ${GRABDISH_HOME}/${service_name}; time ./build.sh>> ${BUILD_LOG_FILE}-${service_name}.log;./deploy.sh "
  print_subheader "${service_name} Completed"
  done


end=$(date +%s)

executionTime=$((end - start))


print_header "Provisioning Completed"
print_subheader "Installation of Oracle Microservices Infrastructure and Data-driven Application is complete. (Took ${executionTime} seconds)"
print_subheader ""




