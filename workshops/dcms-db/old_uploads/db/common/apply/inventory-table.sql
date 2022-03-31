-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


create table inventory (
  inventoryid varchar(16) primary key not null,
  inventorylocation varchar(32),
  inventorycount integer constraint positive_inventory check (inventorycount >= 0) );

insert into inventory values ('sushi', '1468 WEBSTER ST,San Francisco,CA', 0);
insert into inventory values ('pizza', '1469 WEBSTER ST,San Francisco,CA', 0);
insert into inventory values ('burger', '1470 WEBSTER ST,San Francisco,CA', 0);
commit;
