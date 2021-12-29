-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


set echo on

CREATE OR REPLACE PROCEDURE dequeue_order_message(in_wait_option in BINARY_INTEGER, out_order_message OUT varchar2)
IS
  dequeue_options       dbms_aq.dequeue_options_t;
  message_properties    dbms_aq.message_properties_t;
  message_handle        RAW(16);
  message               SYS.AQ$_JMS_TEXT_MESSAGE;
  no_messages           EXCEPTION;
  pragma                exception_init(no_messages, -25228); 
BEGIN
  CASE in_wait_option
  WHEN 0 THEN
    dequeue_options.wait := dbms_aq.NO_WAIT;
  WHEN -1 THEN
    dequeue_options.wait := dbms_aq.FOREVER;
  ELSE
    dequeue_options.wait := in_wait_option;
  END CASE;

  dequeue_options.consumer_name := '$INVENTORY_SERVICE_NAME';

  DBMS_AQ.DEQUEUE(
    queue_name         => '$AQ_USER.$ORDER_QUEUE',
    dequeue_options    => dequeue_options,
    message_properties => message_properties,
    payload            => message,
    msgid              => message_handle);

  out_order_message := message.text_vc;

  EXCEPTION
    WHEN no_messages THEN
      out_order_message := '';
    WHEN OTHERS THEN
      RAISE;
END;
/
show errors

CREATE OR REPLACE PROCEDURE enqueue_inventory_message(in_inventory_message IN VARCHAR2)
IS
   enqueue_options     DBMS_AQ.enqueue_options_t;
   message_properties  DBMS_AQ.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ$_JMS_TEXT_MESSAGE;
BEGIN
  message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
  message.set_text(in_inventory_message);

  DBMS_AQ.ENQUEUE(queue_name => '$AQ_USER.$INVENTORY_QUEUE',
    enqueue_options    => enqueue_options,
    message_properties => message_properties,
    payload            => message,
    msgid              => message_handle);
END;
/
show errors

CREATE OR REPLACE PROCEDURE check_inventory(in_inventory_id IN VARCHAR2, out_inventory_location OUT varchar2)
IS
BEGIN
  update INVENTORYUSER.INVENTORY set inventorycount = inventorycount - 1 
    where inventoryid = in_inventory_id and inventorycount > 0 
    returning inventorylocation into out_inventory_location;
  if sql%rowcount = 0 then
    out_inventory_location := 'inventorydoesnotexist';
  end if;
END;
/
show errors

CREATE OR REPLACE PROCEDURE inventory_service
IS
  order_message VARCHAR2;
  order_inv_id VARCHAR2;
  order_inv_loc VARCHAR2;
  order_json JSON_OBJECT_T;
  inventory_json JSON_OBJECT_T;
BEGIN
  LOOP
    -- Wait for and dequeue the next order message
    dequeue_order_message(
      in_wait_option    => -1,  -- Wait forever
      out_order_message => order_message);

    -- Parse the order message
    order_json := JSON_OBJECT_T.parse(order_message);
    order_inv_id := order_json.get_string('itemid');

    -- Check the inventory
    check_inventory(
      in_inventory_id        => order_inv_id,
      out_inventory_location => order_inv_loc);
      
    -- Construct the inventory message
    inventory_json := new JSON_OBJECT_T;
    inventory_json.put('orderid',           order_json.get_string('orderid'));
    inventory_json.put('itemid',            order_inv_id);
    inventory_json.put('inventorylocation', order_inv_loc);
    inventory_json.put('suggestiveSale',    'beer');

    -- Send the inventory message
    enqueue_inventory_message(
      in_inventory_message   => inventory_json.to_string() );

    -- commit
    commit;
  END LOOP;
END;
/
