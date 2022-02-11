-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


WHENEVER SQLERROR CONTINUE
DROP USER $AQ_USER CASCADE;
DROP USER $ORDER_USER CASCADE;
DROP USER $INVENTORY_USER CASCADE;

WHENEVER SQLERROR EXIT 1
-- AQ User
../../common/apply/admin-aq-create-schema.sql

-- Order User
../../common/apply/admin-order-create-schema.sql

-- Inventory User
../../common/apply/admin-inventory-create-schema.sql
