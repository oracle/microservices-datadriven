-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


connect $DB1_ADMIN_USER/"$DB1_ADMIN_PASSWORD"@$DB1_ALIAS

WHENEVER SQLERROR CONTINUE
DROP USER $AQ_USER CASCADE
DROP USER $ORDER_USER CASCADE
DROP USER $INVENTORY_USER CASCADE
