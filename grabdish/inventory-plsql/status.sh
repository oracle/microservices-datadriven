#!/bin/bash
## Copyright (c) 2021 Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


export TNS_ADMIN=$GRABDISH_HOME/wallet
INVENTORY_DB_SVC="$(state_get INVENTORY_DB_NAME)_tp"
INVENTORY_USER=INVENTORYUSER
DB_PASSWORD=`kubectl get secret dbuser -n msdataworkshop --template={{.data.dbpassword}} | base64 --decode`

U=$INVENTORY_USER
SVC=$INVENTORY_DB_SVC

sqlplus /nolog <<!

connect $U/"$DB_PASSWORD"@$SVC

select state, logging_level from USER_SCHEDULER_JOBS;
SELECT to_char(log_date, 'DD-MON-YY HH24:MI:SS') TIMESTAMP, job_name,
  job_class, operation, status FROM USER_SCHEDULER_JOB_LOG
  WHERE job_name = 'JOB2' ORDER BY log_date;
SELECT to_char(log_date, 'DD-MON-YY HH24:MI:SS') TIMESTAMP, job_name, status,
   SUBSTR(additional_info, 1, 40) ADDITIONAL_INFO
   FROM user_scheduler_job_run_details ORDER BY log_date;
!