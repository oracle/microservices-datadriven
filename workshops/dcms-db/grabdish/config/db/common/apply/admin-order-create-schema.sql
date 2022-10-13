-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


CREATE USER $ORDER_USER IDENTIFIED BY "$ORDER_PASSWORD";
GRANT unlimited tablespace to $ORDER_USER;
GRANT connect, resource TO $ORDER_USER;
GRANT aq_user_role TO $ORDER_USER;
GRANT EXECUTE ON sys.dbms_aq TO $ORDER_USER;
GRANT SODA_APP to $ORDER_USER;
GRANT CREATE JOB to $ORDER_USER;
WHENEVER SQLERROR CONTINUE
GRANT EXECUTE DYNAMIC MLE TO $ORDER_USER;
GRANT EXECUTE ON JAVASCRIPT TO $ORDER_USER;
WHENEVER SQLERROR EXIT 1
