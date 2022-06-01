DECLARE
   dequeue_options     dbms_aq.dequeue_options_t;
   message_properties  dbms_aq.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ$_JMS_TEXT_MESSAGE;

BEGIN
    dequeue_options.wait := dbms_aq.FOREVER;
    dequeue_options.navigation    := dbms_aq.FIRST_MESSAGE;

    dequeue_options.consumer_name := 'bankb_service';
   DBMS_AQ.DEQUEUE(queue_name => 'aquser.banka',
           dequeue_options    => dequeue_options,
           message_properties => message_properties,
           payload            => message,
           msgid              => message_handle);
   COMMIT;
END;

