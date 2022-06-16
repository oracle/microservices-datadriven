--
--  This sample demonstrates how to enqueue a message onto a TEQ using PL/SQL
--

--  There are various payload types supported, including user-defined object, raw, JMS and JSON.
--  This sample uses the JMS payload type.

--  Execute permission on dbms_aq is required.

set serveroutput on;
declare
    dequeue_options     dbms_aq.dequeue_options_t;
    message_properties  dbms_aq.message_properties_t;
    message_handle      raw(16);
    message             SYS.AQ$_JMS_TEXT_MESSAGE;

begin
    -- dequeue_mode determines whether we will consume the message or just browse it and leave it there
    dequeue_options.dequeue_mode  := dbms_aq.remove;
    -- wait controls how long to wait for a message to arrive before giving up
    dequeue_options.wait          := dbms_aq.no_wait;
    -- we must specify navigation so we know where to look in the TEQ
    dequeue_options.navigation    := dbms_aq.first_message;          
    -- set the consumer name 
    dequeue_options.consumer_name := 'my_subscriber';

    -- perform the dequeue
    dbms_aq.dequeue(
        queue_name         => 'my_teq',
        dequeue_options    => dequeue_options,
        message_properties => message_properties,
        payload            => message,
        msgid              => message_handle
    );

    -- print out the message payload
    dbms_output.put_line(message.text);
    
    -- commit the transaction
    commit;
end;
/
