set echo on

--CREATE OR REPLACE PROCEDURE dequeueOrderMessage(p_action OUT varchar2, p_orderid OUT integer)
CREATE OR REPLACE PROCEDURE dequeueOrderMessage(p_orderInfo OUT varchar2)
IS

  dequeue_options       dbms_aq.dequeue_options_t;
  message_properties    dbms_aq.message_properties_t;
  message_handle        RAW(16);
  message               SYS.AQ$_JMS_TEXT_MESSAGE;
  no_messages           EXCEPTION;
  pragma                exception_init(no_messages, -25228);
          
BEGIN

  dequeue_options.wait := -1; 
  -- dequeue_options.navigation := dbms_aq.FIRST_MESSAGE;

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
--  message.get_text(p_orderInfo);

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

 

-- CREATE OR REPLACE PROCEDURE enqueueInventoryMessage(p_action IN VARCHAR2, p_orderid IN NUMBER)
CREATE OR REPLACE PROCEDURE checkInventoryReturnLocation(p_inventoryId IN VARCHAR2)
IS
   enqueue_options     DBMS_AQ.enqueue_options_t;
   message_properties  DBMS_AQ.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ$_JMS_TEXT_MESSAGE;

BEGIN

DECLARE
  l_id t1.id%TYPE;
BEGIN
  INSERT INTO t1 VALUES (t1_seq.nextval, 'FOUR')
  RETURNING id INTO l_id;
  COMMIT;

  DBMS_OUTPUT.put_line('ID=' || l_id);
END;

  message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  -- message.text_vc := p_inventoryInfo;
  message.set_text(p_inventoryInfo);
  -- message.set_string_property('action', p_action);
  -- message.set_int_property('orderid', p_orderid);

  DBMS_AQ.ENQUEUE(queue_name => 'INVENTORYQUEUE',
           enqueue_options    => enqueue_options,
           message_properties => message_properties,
           payload            => message,
           msgid              => message_handle);

  update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?

END;
/
show errors



-- CREATE OR REPLACE PROCEDURE enqueueInventoryMessage(p_action IN VARCHAR2, p_orderid IN NUMBER)
CREATE OR REPLACE PROCEDURE enqueueInventoryMessage(p_inventoryInfo IN VARCHAR2)
IS
   enqueue_options     DBMS_AQ.enqueue_options_t;
   message_properties  DBMS_AQ.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ$_JMS_TEXT_MESSAGE;

BEGIN

  message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  -- message.text_vc := p_inventoryInfo;
  message.set_text(p_inventoryInfo);
  -- message.set_string_property('action', p_action);
  -- message.set_int_property('orderid', p_orderid);

  DBMS_AQ.ENQUEUE(queue_name => 'INVENTORYQUEUE',
           enqueue_options    => enqueue_options,
           message_properties => message_properties,
           payload            => message,
           msgid              => message_handle);

END;
/
show errors
