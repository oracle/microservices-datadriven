-- liquibase formatted sql

--changeset account:2 endDelimiter:/
begin
    -- deposits
    begin
        dbms_aqadm.create_queue_table(
                queue_table        => 'ACCOUNT.deposits_qt',
                queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE',
                multiple_consumers => false);
        dbms_aqadm.create_queue(
                queue_name         => 'ACCOUNT.deposits',
                queue_table        => 'ACCOUNT.deposits_qt');
        dbms_aqadm.start_queue(
                queue_name         => 'ACCOUNT.deposits');
    exception when others then
        dbms_output.put_line(SQLCODE);
    end;

    -- clearances
    begin
        dbms_aqadm.create_queue_table(
                queue_table        => 'ACCOUNT.clearances_qt',
                queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE',
                multiple_consumers => false);
        dbms_aqadm.create_queue(
                queue_name         => 'ACCOUNT.clearances',
                queue_table        => 'ACCOUNT.clearances_qt');
        dbms_aqadm.start_queue(
                queue_name         => 'ACCOUNT.clearances');
    exception when others then
        dbms_output.put_line(SQLCODE);
    end;
end;
/

--rollback exec DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'ACCOUNT.clearances_qt', force => TRUE);
--rollback exec DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => 'ACCOUNT.deposits_qt', force => TRUE);