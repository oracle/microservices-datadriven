-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


WHENEVER SQLERROR EXIT 1
connect $ORDER_USER/"$ORDER_PASSWORD"@$DB1_ALIAS

@../../common/apply/order-collection.sql
@../../common/apply/order-messaging.sql
@../../common/apply/order-db-plsql.sql
@../../common/apply/order-db-deploy.sql
