#!/bin/bash

# shellcheck disable=SC2218

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

INSTALL_ROOT=/microservices
APP_INSTALL_DIR=$INSTALL_ROOT/microservices-datadriven
INFRA_INSTALL_DIR=${INSTALL_ROOT}/microservices-datadriven-infra
INFRA_HOME=${INSTALL_ROOT}/microservices-datadriven-infra
TNS_ADMIN_DIR=${INFRA_HOME}/oci-iaas/grabdish-adapter/database/TNS_ADMIN

SSHD_BANNER_FILE=/etc/ssh/sshd-banner
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
CURL_METADATA_COMMAND="curl -L http://169.254.169.254/opc/v1/instance/metadata"
TEMP_DIR=/grabdish_tmp
PWD=$(dirname "$0")
#ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
ORACLE_HOME=/opt/oracle/product/21c/dbhome_1  # for Docker
DB_PASSWORD="$(curl -L http://169.254.169.254/opc/v1/instance/metadata | jq --raw-output  '.grabdish_database_password')"


INSTALLATION_IN_PROGRESS="
    #################################################################################################
    #                                           WARNING!                                            #
    #   Microservices Data-driven Infrastructure Build  is still in progress.                       #
    #   To check the progress of the installation run -> tail -f ${INSTALL_LOG_FILE_NAME}           #
    #################################################################################################
"

USAGE_INFO="
    =================================================================================================
                                Microservices Data-driven Infrastructure
                            ================================================

    Microservices Data-driven Infrastructure is now available for usage.

    For additional details regarding Microservices Data-driven applications on Oracle Converged Database check,

    https://github.com/oracle/microservices-datadriven

    =================================================================================================
"

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

start=`date +%s`

# Log file
sudo -u ${USER_NAME} touch ${INSTALL_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${INSTALL_LOG_FILE}


# Sending all stdout and stderr to log file
exec >> ${INSTALL_LOG_FILE}
exec 2>&1

print_header "Starting Microservices Data-driven Infrastructure installation process at $(date)"

###########################################
# Create Microservices Data-driven Infrastructure Configuration File
###########################################

print_header "Creating Microservices Datadriven Infrastructure Configuration File." 
cat >${APP_CONFIG_FILE} <<EOF
{
    "app_public_repo":        "$($CURL_METADATA_COMMAND | jq --raw-output  '.app_public_repo')",
    "iaas_public_repo":       "$($CURL_METADATA_COMMAND | jq --raw-output  '.iaas_public_repo')",
    "dbaas_FQDN":             "$($CURL_METADATA_COMMAND | jq --raw-output  '.dbaas_FQDN')",
    "target_compartment_id":  "$($CURL_METADATA_COMMAND | jq --raw-output  '.target_compartment_id')",
    "vcn_id":                 "$($CURL_METADATA_COMMAND | jq --raw-output  '.vcn_id')",
    "subnet_id":              "$($CURL_METADATA_COMMAND | jq --raw-output  '.subnet_id')",
    "image_os":               "$($CURL_METADATA_COMMAND | jq --raw-output  '.image_os')",
    "image_os_version":       "$($CURL_METADATA_COMMAND | jq --raw-output  '.image_os_version')",
    "instance_shape":         "$($CURL_METADATA_COMMAND | jq --raw-output  '.instance_shape')"
}
EOF
print_subheader "Completed."

##################################################
# Mount database, create single instance DB instance
###################################################
print_header "Creating Standalone Database Instance."
sudo chmod 666 /var/run/docker.sock
docker start microservice-database
print_subheader "Database Creation Process Completed."

##################################################
# Install Git and Telnet Packages
# yum install packages are listed here. This same list is used for update too
###################################################

print_header "Installing Git and Telnet Packages."
PACKAGES_TO_INSTALL=(
    git
    telnet
)
print_header "Packages to install ${PACKAGES_TO_INSTALL[@]}"
sudo yum -y install ${PACKAGES_TO_INSTALL[@]} && print_subheader "Successfully installed all yum packages"
print_subheader "Required Packages Installed."


print_header "Creating sshd banner"
sudo touch ${SSHD_BANNER_FILE}
sudo echo "${INSTALLATION_IN_PROGRESS}" > ${SSHD_BANNER_FILE}
sudo echo "${USAGE_INFO}" >> ${SSHD_BANNER_FILE}
sudo echo "Banner ${SSHD_BANNER_FILE}" >> ${SSHD_CONFIG_FILE}
sudo systemctl restart sshd.service

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

#sudo -u ${USER_NAME} echo 'export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export LD_LIBRARY_PATH="$ORACLE_HOME"' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export PATH="$ORACLE_HOME/bin:$PATH"' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME/lib:$ORACLE_HOME' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo export TNS_ADMIN="${TNS_ADMIN_DIR}/"  >> ${USER_HOME}/.bashrc

print_subheader "####################################   2     ####################################"
sudo -u ${USER_NAME} echo export INFRA_INSTALL_DIR=${INFRA_HOME} >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo export INFRA_HOME=${INFRA_HOME} >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo export APP_INSTALL_DIR=${APP_INSTALL_DIR} >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'source ${APP_INSTALL_DIR}/grabdish/env.sh' >> ${USER_HOME}/.bashrc
print_subheader "Completed."

####### Adding environment variables - End #########

#Post Provisioning
print_header "Adding port 1521 to the firewall"
sudo firewall-cmd --permanent --add-port=1521/tcp
sudo firewall-cmd --reload[]
sudo firewall-cmd --list-all
print_subheader "Completed."

print_header "Downloading Microservices Infrastructure and Application from public repositories"
sudo mkdir -p $APP_INSTALL_DIR
sudo mkdir -p $INFRA_INSTALL_DIR
sudo chown -R opc:opc $APP_INSTALL_DIR $INFRA_INSTALL_DIR


app_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output  '.app_public_repo')
iaas_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output  '.iaas_public_repo')

print_subheader $app_public_repo
print_subheader $iaas_public_repo

print_subheader "Downloading Infrastructure from $iaas_public_repo to $APP_INSTALL_DIR"
sudo -u ${USER_NAME} $iaas_public_repo $INFRA_INSTALL_DIR
print_subheader "Download Completed"

print_subheader "Downloading Application from $app_public_repo to $APP_INSTALL_DIR"
sudo -u ${USER_NAME} $app_public_repo $APP_INSTALL_DIR
print_subheader "Download Completed"

sudo chmod -R 755 $APP_INSTALL_DIR $INFRA_INSTALL_DIR


print_header "Updating Database tnsnames.ora, sqlnet.ora and listeners.ora files to match target database"

sudo mkdir -p $TEMP_DIR
sudo chown -R opc:opc $TEMP_DIR
sudo chmod +rw $TEMP_DIR

print_subheader "Creating new tnsnames.ora, sqlnet.ora and listeners.ora file"
sudo -u ${USER_NAME}  bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/database/update_tnsnames-ora.sh"

print_subheader "Copying tnsnames.ora"
#sudo -u ${USER_NAME} cp $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora.bck
#sudo -u ${USER_NAME} cp $TEMP_DIR/tnsnames.ora  $ORACLE_HOME/network/admin/tnsnames.ora
sudo -u ${USER_NAME} cp $TEMP_DIR/tnsnames.ora ${TNS_ADMIN_DIR}/.

print_subheader "Copying listeners.ora"
#sudo -u ${USER_NAME} cp $ORACLE_HOME/network/admin/listeners.ora $ORACLE_HOME/network/admin/listeners.ora.bck
#sudo -u ${USER_NAME} cp $TEMP_DIR/listeners.ora  $ORACLE_HOME/network/admin/listeners.ora
sudo -u ${USER_NAME} cp $TEMP_DIR/listeners.ora ${TNS_ADMIN_DIR}/.

print_subheader "Copying sqlnet.ora"
#sudo -u ${DBUSEUSER_NAMER_NAME} bash -c "cp $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora.bck"
#sudo -u ${USER_NAME} bash -c "cp $TEMP_DIR/sqlnet.ora  $ORACLE_HOME/network/admin/sqlnet.ora"
sudo -u ${USER_NAME} cp $TEMP_DIR/sqlnet.ora ${TNS_ADMIN_DIR}/.
print_subheader "Completed"


#use su - instead of sudo - u
#print_subheader "####################################     8      ####################################"
#sudo -u ${USER_NAME} bash -c "source ${DBUSER_HOME}/.bashrc; lsnrctl reload;lsnrctl status"

sudo chmod -R 777 $APP_INSTALL_DIR $INFRA_INSTALL_DIR
sudo chown -R opc:opc $APP_INSTALL_DIR $INFRA_INSTALL_DIR

#print_subheader "###################################      9     #####################################"
#sudo su - ${USER_NAME}  bash -c "${INFRA_HOME}/oci-iaas/grabdish-adapter/database/db_docker_setup.sh"
# database is already pre-provisioned for the docker image

print_header "Changing Database System and Grabdish Application Passwords."

sudo su - $USER_NAME  bash -c "docker exec microservice-database bash -c \"${DBUSER_HOME}/setPassword.sh ${DB_PASSWORD}\""
print_subheader "Changed SYSTEM Password"

sudo su - $USER_NAME bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/database/change_passwd_orders.sh"
print_subheader "Changed ORDER PDB Password"

sudo su - $USER_NAME bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/database/change_passwd_inventory.sh"
print_subheader "Changed INVENTORY PDB Password"

end=`date +%s`

executionTime=$((end-start))

print_header "Installation of Oracle Microservices Infrastructure and Data-driven Application completed at $(date)"
print_subheader "It took ${executionTime} seconds"

sudo echo "${USAGE_INFO}" > ${SSHD_BANNER_FILE}
