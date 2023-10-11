-- liquibase formatted sql

--changeset atael:1
grant execute on dbms_aq to account;
grant execute on dbms_aqadm to account;
grant execute on dbms_aqin to account;
grant execute on dbms_aqjms_internal to account;

--rollback revoke dbms_aq from ACCOUNT;
--rollback revoke dbms_aqadm from ACCOUNT;
--rollback revoke dbms_aqin from ACCOUNT;
--rollback revoke dbms_aqjms_internal from ACCOUNT;


--changeset atael:2 endDelimiter:/
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

--rollback exec DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'ACCOUNT.clearances_qt', force => TRUE);
--rollback exec DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'ACCOUNT.deposits_qt', force => TRUE);