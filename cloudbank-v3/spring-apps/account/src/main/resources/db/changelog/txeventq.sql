/*
grant execute on sys.dbms_aq to account;
grant execute on sys.dbms_aqadm to account;
grant execute on sys.dbms_aqin to account;
grant execute on sys.dbms_aqjms_internal to account;

begin
    -- deposits
    dbms_aqadm.create_queue_table(
            queue_table        => 'ACCOUNT.deposits_qt',
            queue_payload_type => SYS.AQ$_JMS_TEXT_MESSAGE);
    dbms_aqadm.create_queue(
            queue_name         => 'ACCOUNT.deposits',
            queue_table        => 'ACCOUNT.deposits_qt');
    dbms_aqadm.start_queue(
            queue_name         => 'ACCOUNT.deposits');
    -- clearances
    dbms_aqadm.create_queue_table(
            queue_table        => 'ACCOUNT.clearances_qt',
            queue_payload_type => SYS.AQ$_JMS_TEXT_MESSAGE);
    dbms_aqadm.create_queue(
            queue_name         => 'ACCOUNT.clearances',
            queue_table        => 'ACCOUNT.clearances_qt');
    dbms_aqadm.start_queue(
            queue_name         => 'ACCOUNT.clearances');
end;
/
*/
