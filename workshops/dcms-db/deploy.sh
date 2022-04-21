#!/bin/bash
# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Fail on error
set -eu

# Parameters:
_lang=${1-plsql}      # plsql(default) / js

# Make sure this is executed and not sourced
if (return 0 2>/dev/null) ; then
  echo "ERROR: Usage './deploy.sh plsql/js'"
  exit 1
fi

# Get the setup status
if ! DCMS_STATUS=$(provisioning-get-status $DCMS_STATE); then
  echo "ERROR: Unable to get workshop provisioning status"
  exit 1
fi

if [[ ! "$DCMS_STATUS" =~ applied ]]; then
  echo "ERROR: Setup must be completed before deploy can be run"
  exit 1
fi

# Source the setup functions
source $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/setup_functions.env

# Check this is needed
if state_done DEPLOYED; then
  echo "Grabdish is already deployed"
  exit
fi

# Explain what is happening
echo
echo "To deploy GrabDish we need to collect the DB password and application password and deploy"
echo "the application on the ORDS server and in the database."
echo
echo "The log file is $DCMS_LOG_DIR/config.log"

# Collect DB password
echo
echo "You get to choose the password for the autonomous database.  Please make a note"
echo "of the password that you choose because you will need it later."
DB_PASSWORD=""
collect_db_password
echo

if ! state_done DB_LOCKDOWN; then
  # Set DB admin password
  echo
  echo "Setting the DB password..."
  set_adbs_admin_password "$(state_get DB_OCID)" >>$DCMS_LOG_DIR/config.log 2>&1
  state_set_done DB_LOCKDOWN >>$DCMS_LOG_DIR/config.log 2>&1
fi

#### SETUP ORDS

# Create the ORDS schema
echo "Creating the ORDS schema in the database..."
create_ords_schema $(state_get ORDS_SCHEMA_NAME) 'admin' "$(state_get DB_ALIAS)" >>$DCMS_LOG_DIR/config.log 2>&1

echo "Configuring the ORDS server..."
_setup_func=/tmp/setup_functions.env
# Upload setup functions
scp -o StrictHostKeyChecking=no -i $(state_get SSH_PRIVATE_KEY_FILE) $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/setup_functions.env opc@$(state_get ORDS_ADDRESS):/tmp >>$DCMS_LOG_DIR/config.log 2>&1

_tns_zip=/tmp/adb_wallet.zip
# Upload tns zip file
scp -o StrictHostKeyChecking=no -i $(state_get SSH_PRIVATE_KEY_FILE) $(state_get TNS_ADMIN_ZIP_FILE) opc@$(state_get ORDS_ADDRESS):/tmp >>$DCMS_LOG_DIR/config.log 2>&1

# Configure customer managed ORDS
ssh -o StrictHostKeyChecking=no -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) >>$DCMS_LOG_DIR/config.log 2>&1 <<!
  sudo su - oracle
  source ${_setup_func}
  DB_PASSWORD='$DB_PASSWORD'
  setup_adbs_customer_managed_ords $(state_get DB_ALIAS) ${_tns_zip} $(state_get ORDS_SCHEMA_NAME)
!

#### DEPLOY GRABDISH

# Collect UI password
echo
echo "You get to choose the password for the application.  Please make a note"
echo "of the password that you choose because you will need it later."
UI_PASSWORD=""
collect_ui_password
echo

echo
echo "Deploying the GrabDish Application in the ORDS server..."
# Upload the Grabdish code
_grabdish_code=/home/oracle/grabdish
cd $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP
zip -r /tmp/grabdish.zip grabdish >>$DCMS_LOG_DIR/config.log 2>&1
scp -o StrictHostKeyChecking=no -i $(state_get SSH_PRIVATE_KEY_FILE) /tmp/grabdish.zip opc@$(state_get ORDS_ADDRESS):/tmp >>$DCMS_LOG_DIR/config.log 2>&1
ssh -o StrictHostKeyChecking=no -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS)  >>$DCMS_LOG_DIR/config.log 2>&1 <<!
  sudo su - oracle
  cd
  rm -rf grabdish
  unzip /tmp/grabdish.zip
!

# Deploy Grabdish on ORDS
ssh -o StrictHostKeyChecking=no -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) >>$DCMS_LOG_DIR/config.log 2>&1 <<!
sudo su - oracle
source ${_setup_func}
UI_PASSWORD=$UI_PASSWORD
deploy_grabdish_on_ords ${_grabdish_code}
!

# Grabdish DB Setup
echo "Deploying Grabdish in the database..."
setup_grabdish_in_db $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/grabdish "$_lang" "$_lang" $(state_get QUEUE_TYPE) $(state_get DB_ALIAS) >>$DCMS_LOG_DIR/config.log 2>&1

### START ORDS

# Enable and start ORDS
echo "Starting the ORDS server..."
ssh -o StrictHostKeyChecking=no -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) >>$DCMS_LOG_DIR/config.log 2>&1 <<!
  sudo su - root
  
  # Open Firewall
	firewall-cmd --zone=public --add-port 8080/tcp --permanent
	systemctl restart firewalld

	# Configure ORDS systemctl and restart
  ln -s /etc/init.d/ords /opt/oracle/ords/ords
  systemctl enable ords
  systemctl restart ords
!

state_set_done DEPLOYED
if test "$_lang" == "plsql"; then
  state_set ORDER_LANG 'PL/SQL'
  state_set INVENTORY_LANG 'PL/SQL'
else
  state_set ORDER_LANG 'JavaScript'
  state_set INVENTORY_LANG 'JavaScript'
fi

echo
echo "Deployment has completed"