set echo on

--CREATE OR REPLACE PROCEDURE deqOrdMsg(p_action OUT varchar2, p_orderid OUT integer)
CREATE OR REPLACE PROCEDURE deqOrdMsg(p_orderInfo OUT varchar2)
IS

  dequeue_options       dbms_aq.dequeue_options_t;
  message_properties    dbms_aq.message_properties_t;
  message_handle        RAW(16);
  message               SYS.AQ$_JMS_TEXT_MESSAGE;
  no_messages           EXCEPTION;
  pragma                exception_init(no_messages, -25228);

BEGIN

--  dequeue_options.wait := 0; -- don't wait if there is currently no message
--  dequeue_options.wait := -1; -- wait forever
  dequeue_options.wait := 60; -- wait 60 seconds
  dequeue_options.navigation := dbms_aq.FIRST_MESSAGE;

  DBMS_AQ.DEQUEUE(
    queue_name => 'ORDERQUEUE',
    dequeue_options => dequeue_options,
    message_properties => message_properties,
    payload => message,
    msgid => message_handle);
    COMMIT;

--  p_action := message.get_string_property('action');
--  p_orderid := message.get_int_property('orderid');
  p_orderInfo := message.text_vc;

  EXCEPTION
    WHEN no_messages THEN
    BEGIN
      p_orderInfo := '';
--      p_action := '';
--      p_orderid := 0;
    END;
    WHEN OTHERS THEN
     RAISE;
END;
/
show errors


CREATE OR REPLACE PROCEDURE enqInvMsg(p_action IN VARCHAR2, p_orderid IN NUMBER)
IS
   enqueue_options     DBMS_AQ.enqueue_options_t;
   message_properties  DBMS_AQ.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ$_JMS_TEXT_MESSAGE;

BEGIN

  message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  message.set_string_property('action', p_action);
  message.set_int_property('orderid', p_orderid);

  DBMS_AQ.ENQUEUE(queue_name => 'INVENTORYQUEUE',
           enqueue_options    => enqueue_options,
           message_properties => message_properties,
           payload            => message,
           msgid              => message_handle);

END;
/
show errors
