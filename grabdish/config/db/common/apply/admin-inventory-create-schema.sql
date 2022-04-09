-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


CREATE USER $INVENTORY_USER IDENTIFIED BY "$INVENTORY_PASSWORD";
GRANT unlimited tablespace to $INVENTORY_USER;
GRANT connect, resource TO $INVENTORY_USER;
GRANT aq_user_role TO $INVENTORY_USER;
GRANT EXECUTE ON sys.dbms_aq TO $INVENTORY_USER;
-- For inventory-plsql deployment
GRANT CREATE JOB to $INVENTORY_USER; 
GRANT EXECUTE ON sys.DBMS_SCHEDULER TO $INVENTORY_USER;
GRANT select on GV$SESSION to inventoryuser;
GRANT select on DBA_QUEUE_SCHEDULES to inventoryuser;