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

#APP_INSTALL_DIR=${USER_HOME}/microservices-datadriven
#INFRA_INSTALL_DIR=${USER_HOME}/microservices-datadriven-infra
#INFRA_HOME=${USER_HOME}/microservices-datadriven-infra

INSTALL_ROOT=/microservices
APP_INSTALL_DIR=$INSTALL_ROOT/microservices-datadriven
INFRA_INSTALL_DIR=${INSTALL_ROOT}/microservices-datadriven-infra
INFRA_HOME=${INSTALL_ROOT}/microservices-datadriven-infra
TNS_ADMIN_DIR=${INFRA_HOME}/oci-iaas/grabdish-adapter/database/TNS_ADMIN

SSHD_BANNER_FILE=/etc/ssh/sshd-banner
SSHD_CONFIG_FILE=/etc/ssh/sshd_config
UPDATE_SCRIPT_FILE=update-kit.sh
UPDATE_SCRIPT_WITH_PATH=/usr/local/bin/${UPDATE_SCRIPT_FILE}
UPDATE_SCRIPT_LOG_FILE=${USER_HOME}/${UPDATE_SCRIPT_FILE}.log
CURL_METADATA_COMMAND="curl -L http://169.254.169.254/opc/v1/instance/metadata"
TEMP_DIR=/grabdish_tmp
PWD=$(dirname "$0")
#ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1
#ORACLE_HOME=/opt/oracle/product/21c/dbhome_1  # for Docker
ORACLE_HOME="/usr/lib/oracle/19.11/client64"  # for Docker Host -- i.e. Compute


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

start=`date +%s`

# Log file
sudo -u ${USER_NAME} touch ${INSTALL_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${INSTALL_LOG_FILE}

echo "##################################################" | tee -a  ${INSTALL_LOG_FILE}
echo "# Starting Microservices Data-driven Infrastructure installation process at ${start} " | tee -a ${INSTALL_LOG_FILE}
echo "##################################################" | tee -a  ${INSTALL_LOG_FILE}

###########################################
# Create Microservices Data-driven Infrastructure Configuration File
###########################################
echo "" | tee -a ${INSTALL_LOG_FILE}
echo "########################################################################" | tee -a ${INSTALL_LOG_FILE}
echo "# 1. Create Microservices Datadriven Infrastructure Configuration File." | tee -a ${INSTALL_LOG_FILE}
echo "########################################################################" | tee -a ${INSTALL_LOG_FILE}
sudo -u ${USER_NAME} touch ${APP_CONFIG_FILE}

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

echo "Completed." | tee -a ${INSTALL_LOG_FILE}

##################################################
# Mount database, create single instance DB instance
###################################################
echo "" | tee -a ${INSTALL_LOG_FILE}
echo "########################################################################" | tee -a ${INSTALL_LOG_FILE}
echo "# 2. Creating Standalone Database Instance." | tee -a ${INSTALL_LOG_FILE}
echo "########################################################################" | tee -a ${INSTALL_LOG_FILE}

sudo mount /u01 | tee -a ${INSTALL_LOG_FILE}
sudo /u01/ocidb/GenerateNetconfig.sh -a | tee -a ${INSTALL_LOG_FILE}
sudo /u01/ocidb/buildsingle.sh -s| tee -a ${INSTALL_LOG_FILE}

echo "Database Creation Process Completed." | tee -a ${INSTALL_LOG_FILE}

##################################################
# Install Git and Telnet Packages
# yum install packages are listed here. This same list is used for update too
###################################################
echo "" | tee -a ${INSTALL_LOG_FILE}
echo "########################################################################" | tee -a ${INSTALL_LOG_FILE}
echo "# 3.Installing Git and Telnet Packages ." | tee -a ${INSTALL_LOG_FILE}
echo "########################################################################" | tee -a ${INSTALL_LOG_FILE}

PACKAGES_TO_INSTALL=(
    git
    telnet
)

echo "Packages to install ${PACKAGES_TO_INSTALL[@]}" | tee -a ${INSTALL_LOG_FILE}
sudo yum -y install ${PACKAGES_TO_INSTALL[@]} && echo "#################### Successfully installed all yum packages #####################" | tee -a ${INSTALL_LOG_FILE}

echo "Required Packages Installed." | tee -a ${INSTALL_LOG_FILE}

# Sending all stdout and stderr to log file
exec >> ${INSTALL_LOG_FILE}
exec 2>&1

echo "Creating sshd banner"
sudo touch ${SSHD_BANNER_FILE}
sudo echo "${INSTALLATION_IN_PROGRESS}" > ${SSHD_BANNER_FILE}
sudo echo "${USAGE_INFO}" >> ${SSHD_BANNER_FILE}
sudo echo "Banner ${SSHD_BANNER_FILE}" >> ${SSHD_CONFIG_FILE}
sudo systemctl restart sshd.service

####### Adding environment variables #########
echo "Adding environment variable so terraform can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export TF_VAR_auth=InstancePrincipal' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_region=$(oci-metadata -g regionIdentifier --value-only)" >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo "export TF_VAR_tenancy_ocid=$(oci-metadata -g tenancy_id --value-only)" >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo -u ${USER_NAME} echo 'export OCI_CLI_AUTH=instance_principal' >> ${USER_HOME}/.bashrc

echo "Adding environment variable so oci-cli can be AuthN using instance principal"
sudo echo 'export OCI_CLI_AUTH=instance_principal' >> /etc/bashrc

####### Adding environment variables - End #########

####### Generating upgrade script #########
DOLLAR_SIGN="$"

echo "Creating update script"
echo "----------------------"
cat > ${UPDATE_SCRIPT_WITH_PATH} <<EOL
#!/bin/bash

PACKAGES_TO_UPDATE=(
    git
    telnet
)

# Log file
sudo -u ${USER_NAME} touch ${UPDATE_SCRIPT_LOG_FILE}
sudo -u ${USER_NAME} chmod +w ${UPDATE_SCRIPT_LOG_FILE}

exec > >(tee ${UPDATE_SCRIPT_LOG_FILE})
exec 2>&1

echo "Updating  Microservices Datadriven Infrastructure"
echo "----------------------"

echo "Packages to update ${DOLLAR_SIGN}{PACKAGES_TO_UPDATE[@]}"
sudo yum -y install ${DOLLAR_SIGN}{PACKAGES_TO_UPDATE[@]} && echo "#################### Successfully updated all yum packages #####################"

echo "-----------------------------------"
echo "Update Installation of Database is complete"

EOL
####### Generating upgrade script -End #########
echo "Update script creation complete"

sudo chmod +x ${UPDATE_SCRIPT_WITH_PATH}

#Post Provisioning

sudo firewall-cmd --permanent --add-port=1521/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all


sudo mkdir -p $APP_INSTALL_DIR
sudo mkdir -p $INFRA_INSTALL_DIR
sudo chown -R opc:opc $APP_INSTALL_DIR $INFRA_INSTALL_DIR


app_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output  '.app_public_repo')
iaas_public_repo=$($CURL_METADATA_COMMAND | jq --raw-output  '.iaas_public_repo')

sudo -u ${USER_NAME} echo $app_public_repo
sudo -u ${USER_NAME} echo $iaas_public_repo


sudo -u ${USER_NAME} $app_public_repo $APP_INSTALL_DIR
sudo -u ${USER_NAME} $iaas_public_repo $INFRA_INSTALL_DIR
sudo -u ${USER_NAME} echo "####################################   1   ####################################"

sudo chmod -R 777 $APP_INSTALL_DIR $INFRA_INSTALL_DIR

sudo -u ${USER_NAME} echo 'export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export LD_LIBRARY_PATH="$ORACLE_HOME"' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export PATH="$ORACLE_HOME/bin:$PATH"' >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME/lib:$ORACLE_HOME' >> ${USER_HOME}/.bashrc

sudo -u ${USER_NAME} echo "####################################   2     ####################################"
sudo -u ${USER_NAME} echo export INFRA_INSTALL_DIR=${INFRA_HOME} >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo export INFRA_HOME=${INFRA_HOME} >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo export APP_INSTALL_DIR=${APP_INSTALL_DIR} >> ${USER_HOME}/.bashrc
sudo -u ${USER_NAME} echo 'source ${APP_INSTALL_DIR}/grabdish/env.sh' >> ${USER_HOME}/.bashrc

sudo -u ${USER_NAME} echo "####################################    3   ####################################"
sudo -u ${DBUSER_NAME} bash -c "echo export ORACLE_HOME=/u01/app/oracle/product/19c/dbhome_1 >> ${DBUSER_HOME}/.bashrc"
sudo -u ${DBUSER_NAME} bash -c "echo export LD_LIBRARY_PATH=$ORACLE_HOME >> ${DBUSER_HOME}/.bashrc"
sudo -u ${DBUSER_NAME} bash -c "echo export PATH=$ORACLE_HOME/bin:$PATH >> ${DBUSER_HOME}/.bashrc"
sudo -u ${DBUSER_NAME} bash -c "echo export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME/lib:$ORACLE_HOME >> ${DBUSER_HOME}/.bashrc"

sudo -u ${USER_NAME}  echo "####################################   4    ####################################"
#sudo -u ${DBUSER_NAME} bash -c "echo export INFRA_INSTALL_DIR=${INFRA_HOME} >> ${DBUSER_HOME}/.bashrc"
#sudo -u ${DBUSER_NAME} bash -c "echo export INFRA_HOME=${INFRA_HOME} >> ${DBUSER_HOME}/.bashrc"
#sudo -u ${DBUSER_NAME} bash -c "echo source ${APP_INSTALL_DIR}/grabdish/env.sh >> ${DBUSER_HOME}/.bashrc"


sudo -u ${USER_NAME} echo "####################################   5   ####################################"
sudo -u ${DBUSER_NAME} bash -c "echo export INFRA_INSTALL_DIR=${INFRA_HOME} >> ${DBUSER_HOME}/.bashrc"
sudo -u ${DBUSER_NAME} bash -c "echo export INFRA_HOME=${INFRA_HOME} >> ${DBUSER_HOME}/.bashrc"
sudo -u ${DBUSER_NAME} bash -c "echo export APP_INSTALL_DIR=${APP_INSTALL_DIR} >> ${DBUSER_HOME}/.bashrc"
sudo -u ${DBUSER_NAME} bash -c "echo source ${APP_INSTALL_DIR}/grabdish/env.sh >> ${DBUSER_HOME}/.bashrc"


sudo -u ${USER_NAME} echo "####################################   6   ####################################"
#update tnsnames.ora
sudo -u ${USER_NAME} bash -c "source ${USER_HOME}/.bashrc"
sudo mkdir -p $TEMP_DIR
sudo chown -R opc:opc $TEMP_DIR
sudo chmod +rw $TEMP_DIR

sudo -u ${USER_NAME} echo "####################################     7    ####################################"
sudo -u ${USER_NAME}  bash -c "$INFRA_HOME/oci-iaas/grabdish-adapter/database/update_tnsnames-ora.sh"

sudo -u ${DBUSER_NAME} cp $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora.bck
sudo -u ${DBUSER_NAME} cp $TEMP_DIR/tnsnames.ora  $ORACLE_HOME/network/admin/tnsnames.ora

sudo -u ${DBUSER_NAME} cp $ORACLE_HOME/network/admin/listeners.ora $ORACLE_HOME/network/admin/listeners.ora.bck
sudo -u ${DBUSER_NAME} cp $TEMP_DIR/listeners.ora  $ORACLE_HOME/network/admin/listeners.ora

sudo -u ${DBUSER_NAME} bash -c "cp $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora.bck"
sudo -u ${DBUSER_NAME} bash -c "cp $TEMP_DIR/sqlnet.ora  $ORACLE_HOME/network/admin/sqlnet.ora"

#use su - instead of sudo - u
sudo -u ${USER_NAME} echo "####################################     8      ####################################"
sudo -u ${DBUSER_NAME} bash -c "source ${DBUSER_HOME}/.bashrc; lsnrctl reload;lsnrctl status"

sudo chmod -R 777 $APP_INSTALL_DIR $INFRA_INSTALL_DIR
sudo chown -R opc:opc $APP_INSTALL_DIR $INFRA_INSTALL_DIR

sudo -u ${USER_NAME} echo "###################################      9     #####################################"
sudo -u ${DBUSER_NAME}  bash -c "source ${DBUSER_HOME}/.bashrc;source ${APP_INSTALL_DIR}/grabdish/env.sh;${INFRA_HOME}/oci-iaas/grabdish-adapter/database/db_setup.sh"

sudo -u ${USER_NAME} echo "###################################      10    #####################################"

end=`date +%s`

executionTime=$((end-start))

echo "--------------------------------------------------------------"
echo "Installation of Oracle Microservices Infrastructure and Data-driven Application is complete. (Took ${executionTime} seconds)"

sudo echo "${USAGE_INFO}" > ${SSHD_BANNER_FILE}

exec -l $SHELL