-- Run as the application owner (or with CURRENT_SCHEMA set to that owner).
-- Additive and repeatable: existing tickets, assistance, and blockchain rows remain.
whenever sqlerror exit failure
whenever oserror exit failure
set echo off verify off
alter session set ddl_lock_timeout=30;
declare
    present number;
begin
    select count(*) into present from all_tab_columns
    where owner = sys_context('USERENV', 'CURRENT_SCHEMA')
      and table_name = 'SUPPORT_TICKET' and column_name = 'RESOLUTION';
    if present = 0 then
        execute immediate 'alter table support_ticket add (resolution clob)';
    end if;
    select count(*) into present from all_tab_columns
    where owner = sys_context('USERENV', 'CURRENT_SCHEMA')
      and table_name = 'TICKET_ASSISTANCE' and column_name = 'SUGGESTED_RESOLUTION';
    if present = 0 then
        execute immediate 'alter table ticket_assistance add (suggested_resolution clob)';
    end if;
end;
/
@@seed-policies.sql
@@seed-resolutions.sql
prompt Assistance schema and reference cases are ready. Restart Java to index reference cases.
