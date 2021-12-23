-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


connect $DB1_ADMIN_USER/"$DB1_ADMIN_PASSWORD"@$DB1_ALIAS

WHENEVER SQLERROR CONTINUE
DROP USER $AQ_USER CASCADE;
DROP USER $ORDER_USER CASCADE;

WHENEVER SQLERROR EXIT 1

-- AQ User
@$COMMON_SCRIPT_HOME/admin-aq-create-schema.sql
-- For AQ Propagation
GRANT CREATE DATABASE LINK TO $AQ_USER;

-- Order User
@$COMMON_SCRIPT_HOME/admin-order-create-schema.sql
