-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


WHENEVER SQLERROR EXIT 1
connect $INVENTORY_USER/"$INVENTORY_PASSWORD"@$DB2_ALIAS

create table inventory (
  inventoryid varchar(16) PRIMARY KEY NOT NULL,
  inventorylocation varchar(32),
  inventorycount integer CONSTRAINT positive_inventory CHECK (inventorycount >= 0) );

insert into inventory values ('sushi', '1468 WEBSTER ST,San Francisco,CA', 0);
insert into inventory values ('pizza', '1469 WEBSTER ST,San Francisco,CA', 0);
insert into inventory values ('burger', '1470 WEBSTER ST,San Francisco,CA', 0);
commit;
