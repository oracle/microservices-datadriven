#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


if ! test -z "$INVENTORY_DB_TNS_ADMIN"; then
  export TNS_ADMIN="$INVENTORY_DB_TNS_ADMIN"
else
  export TNS_ADMIN=$GRABDISH_HOME/wallet
fi
INVENTORY_DB_SVC="$(state_get INVENTORY_DB_NAME)_tp"
INVENTORY_USER=INVENTORYUSER
DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`

U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC

sqlplus /nolog <<!

connect $U/"$DB_PASSWORD"@$SVC

BEGIN
  DBMS_SCHEDULER.STOP_JOB('inventory_plsql_service');
  EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

BEGIN
  DBMS_SCHEDULER.DROP_JOB('inventory_plsql_service');
  EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
!