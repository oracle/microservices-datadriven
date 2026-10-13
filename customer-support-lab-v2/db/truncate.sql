-- Destructive local-demo reset: stop the app and verify the schema first.
-- Approval history has a non-cascading FK; do not partly reset its ticket data.
whenever sqlerror exit failure
declare
    approval_table_count number;
begin
    select count(*) into approval_table_count from user_tables
    where table_name = 'TICKET_APPROVAL_HISTORY';
    if approval_table_count > 0 then
        raise_application_error(-20002,
            'Blockchain chapter installed: use a fresh lab or explicitly drop its approval table before reset');
    end if;
end;
/
truncate table failed_ticket_event;
truncate table ticket_event_processed;
truncate table support_ticket cascade;
