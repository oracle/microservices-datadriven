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

# Source the setup functions
source $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/setup_functions.env

# Collect DB password
DB_PASSWORD=""
collect_db_password

if ! state_done DB_LOCKDOWN; then
  # Set DB admin password
  set_adbs_admin_password "$(state_get DB_OCID)"
  state_set_done DB_LOCKDOWN
fi

_setup_func=/tmp/setup_functions.env
# Upload tns zip file
scp -i $(state_get SSH_PRIVATE_KEY_FILE) $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/setup_functions.env opc@$(state_get ORDS_ADDRESS):/tmp

_tns_zip=/tmp/adb_wallet.zip
# Upload tns zip file
scp -i $(state_get SSH_PRIVATE_KEY_FILE) $(state_get TNS_ADMIN_ZIP_FILE) opc@$(state_get ORDS_ADDRESS):/tmp

# Configure customer managed ORDS
ssh -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
  sudo su - oracle
  source ${_setup_func}
  DB_PASSWORD='$DB_PASSWORD'
  setup_adbs_customer_managed_ords $(state_get DB_ALIAS) ${_tns_zip}
!

#### DEPLOY GRABDISH

# Collect UI password
UI_PASSWORD=""
collect_ui_password

# Upload the Grabdish code
_grabdish_code=/home/oracle/grabdish
cd $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP
zip -r /tmp/grabdish.zip grabdish
scp -i $(state_get SSH_PRIVATE_KEY_FILE) /tmp/grabdish.zip opc@$(state_get ORDS_ADDRESS):/tmp
ssh -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
  sudo su - oracle
  cd
  rm -rf grabdish
  unzip /tmp/grabdish.zip
!

# Deploy Grabdish on ORDS
ssh -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
sudo su - oracle
source ${_setup_func}
UI_PASSWORD=$UI_PASSWORD
deploy_grabdish_on_ords ${_grabdish_code}
!

# Grabdish DB Setup
setup_grabdish_in_db $MSDD_WORKSHOP_CODE/$DCMS_WORKSHOP/grabdish "$_lang" "$_lang" $(state_get QUEUE_TYPE) $(state_get DB_ALIAS)

# Enable and start ORDS
ssh -i $(state_get SSH_PRIVATE_KEY_FILE) opc@$(state_get ORDS_ADDRESS) <<!
  sudo su - root
  
  # Open Firewall
	firewall-cmd --zone=public --add-port 8080/tcp --permanent
	systemctl restart firewalld

	# Configure ORDS systemctl and restart
  ln -s /etc/init.d/ords /opt/oracle/ords/ords
  systemctl enable ords
  systemctl restart ords
!
