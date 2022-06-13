-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


CREATE USER $AQ_USER IDENTIFIED BY "$AQ_PASSWORD";
GRANT unlimited tablespace to $AQ_USER;
GRANT connect, resource TO $AQ_USER;
GRANT aq_user_role TO $AQ_USER;
GRANT EXECUTE ON sys.dbms_aqadm TO $AQ_USER;
GRANT EXECUTE ON sys.dbms_aq TO $AQ_USER;
