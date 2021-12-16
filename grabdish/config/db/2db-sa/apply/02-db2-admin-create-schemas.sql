-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


connect $DB2_ADMIN_USER/"$DB2_ADMIN_PASSWORD"@$DB2_ALIAS

WHENEVER SQLERROR CONTINUE
DROP USER $AQ_USER CASCADE;
DROP USER $INVENTORY_USER CASCADE;

WHENEVER SQLERROR EXIT 1

-- AQ User
@$COMMON_SCRIPT_HOME/admin-aq-create-schema.sql
-- For AQ Propagation
GRANT CREATE DATABASE LINK TO $AQ_USER;


-- Inventory User
@$COMMON_SCRIPT_HOME/admin-inventory-create-schema.sql
