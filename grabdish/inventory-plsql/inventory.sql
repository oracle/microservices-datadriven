-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

CREATE OR REPLACE PROCEDURE inventory_plsql
IS
  dequeue_options       dbms_aq.dequeue_options_t;
  enqueue_options       dbms_aq.enqueue_options_t;
  message_properties    dbms_aq.message_properties_t;
  message_handle        RAW(16);
  message               SYS.AQ$_JMS_TEXT_MESSAGE;

  order_inv_id VARCHAR2(23767);
  order_inv_loc VARCHAR2(23767);
  order_json JSON_OBJECT_T;
  inventory_json JSON_OBJECT_T;
BEGIN
  LOOP
    -- Wait for and dequeue the next order message
    dequeue_options.wait := dbms_aq.FOREVER;
    dequeue_options.navigation    := dbms_aq.FIRST_MESSAGE;

    dequeue_options.consumer_name := 'inventory_service';
    DBMS_AQ.DEQUEUE(
      queue_name => 'AQ.ORDERQUEUE',
      dequeue_options => dequeue_options,
      message_properties => message_properties,
      payload => message,
      msgid => message_handle);

    -- Parse the order message
    order_json := JSON_OBJECT_T.parse(message.text_vc);
    order_inv_id := order_json.get_string('itemid');

    -- Check the inventory
    update INVENTORYUSER.INVENTORY set inventorycount = inventorycount - 1 
      where inventoryid = order_inv_id and inventorycount > 0 returning inventorylocation 
      into order_inv_loc;
    if sql%rowcount = 0 then
      order_inv_loc := 'inventorydoesnotexist';
    end if;

    -- Construct the inventory message
    inventory_json := new JSON_OBJECT_T;
    inventory_json.put('orderid', order_json.get_string('orderid'));
    inventory_json.put('itemid', order_inv_id);
    inventory_json.put('inventorylocation', order_inv_loc);
    inventory_json.put('suggestiveSale', 'beer');

    -- Send the inventory message
    message := SYS.AQ$_JMS_TEXT_MESSAGE.construct;
    message.set_text(inventory_json.to_string());
    DBMS_AQ.ENQUEUE(queue_name => 'AQ.INVENTORYQUEUE',
      enqueue_options    => enqueue_options,
      message_properties => message_properties,
      payload            => message,
      msgid              => message_handle);

    -- commit
    commit;
  END LOOP;
END;
/
