-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


CREATE USER $ORDER_USER IDENTIFIED BY "$ORDER_PASSWORD";
GRANT unlimited tablespace to $ORDER_USER;
GRANT connect, resource TO $ORDER_USER;
GRANT aq_user_role TO $ORDER_USER;
GRANT EXECUTE ON sys.dbms_aq TO $ORDER_USER;
GRANT SODA_APP to $ORDER_USER;
--This is all we want but table hasn't been created yet... GRANT select on AQ.orderqueuetable to $ORDER_USER;
GRANT SELECT ANY TABLE TO $ORDER_USER;
GRANT select on gv\$session to $ORDER_USER;
GRANT select on v\$diag_alert_ext to $ORDER_USER;
GRANT select on DBA_QUEUE_SCHEDULES to $ORDER_USER;
