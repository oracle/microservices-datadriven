-- liquibase formatted sql
-- changeset insert_static:1 runAlways:true failOnError:true
TRUNCATE TABLE INVENTORY;
INSERT into INVENTORY values ('sushi', '1468 WEBSTER ST,San Francisco,CA', 0);
INSERT into INVENTORY values ('pizza', '1469 WEBSTER ST,San Francisco,CA', 0);
INSERT into INVENTORY values ('burger', '1470 WEBSTER ST,San Francisco,CA', 0);
-- rollback TRUNCATE TABLE INVENTORY;;