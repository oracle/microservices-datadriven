+++
archetype = "page"
title = "Create Queues in the Database"
weight = 4
+++


1. Create the queues

  Connect to the database as the `ADMIN` user and execute the following statements to give the `account` user the necessary permissions to use queues. **Note**: module 2, Task 9 provided details on how to connect to the database.

    ```sql
    grant execute on dbms_aq to account;
    grant execute on dbms_aqadm to account;
    grant execute on dbms_aqin to account;
    commit;
    ```

  Now connect as the `account` user and create the queues by executing these statements (replace `[TNS-ENTRY]` with your environment information). You can get the TNS Entries by executing `SHOW TNS` in the sql shell:

    ```sql
    connect account/Welcome1234##@[TNS-ENTRY];
    
    begin
        -- deposits
        dbms_aqadm.create_queue_table(
            queue_table        => 'deposits_qt',
            queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE');
        dbms_aqadm.create_queue(
            queue_name         => 'deposits',
            queue_table        => 'deposits_qt');
        dbms_aqadm.start_queue(
            queue_name         => 'deposits');
        -- clearances 
        dbms_aqadm.create_queue_table(
            queue_table        => 'clearances_qt',
            queue_payload_type => 'SYS.AQ$_JMS_TEXT_MESSAGE');
        dbms_aqadm.create_queue(
            queue_name         => 'clearances',
            queue_table        => 'clearances_qt');
        dbms_aqadm.start_queue(
            queue_name         => 'clearances');
    end;
    /
    ```

  You have created two queues named `deposits` and `clearances`. Both of them use the JMS `TextMessage` format for the payload.
