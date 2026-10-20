-- Run as the application user after committing at least one approval.
whenever sqlerror exit failure
set serveroutput on
declare
    verified number;
begin
    dbms_blockchain_table.verify_rows(
        schema_name => user,
        table_name => 'TICKET_APPROVAL_HISTORY',
        number_of_rows_verified => verified,
        verify_signature => false);
    dbms_output.put_line('Verified blockchain rows: ' || verified);
end;
/
