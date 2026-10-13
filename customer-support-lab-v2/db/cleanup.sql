-- Destructive removal of the local lab schema.
whenever sqlerror exit failure
-- Optional chapter uses zero-day table retention for deliberate full cleanup.
declare
    approval_table_count number;
begin
    select count(*) into approval_table_count from user_tables
    where table_name = 'TICKET_APPROVAL_HISTORY';
    if approval_table_count > 0 then
        execute immediate 'drop table ticket_approval_history';
    end if;
end;
/
drop table ticket_policy_match;
drop table ticket_assistance;
drop table support_policy;
drop table failed_ticket_event;
drop table ticket_event_processed;
drop table related_ticket;
drop table support_ticket;

-- drop the user to completely remove the lab schema
drop user &&app_username cascade;
