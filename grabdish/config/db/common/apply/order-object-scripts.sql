-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- frontend place order (POST)
CREATE OR REPLACE PROCEDURE frontend_place_order (
  serviceName IN varchar2,
  commandName IN varchar2,
  orderId     IN varchar2,
  orderItem   IN varchar2,
  deliverTo   IN varchar2)
IS
AUTHID CURRENT_USER
BEGIN
  place_order(
    orderid => orderId,
    itemid  => orderItem,
    deliverylocation => deliverTo);
END;
/
show errors


-- place order microserice (GET)
CREATE OR REPLACE PROCEDURE place_order (
  orderid           IN varchar2,
  itemid            IN varchar2,
  deliverylocation  IN varchar2)
AUTHID CURRENT_USER
IS
  order_json            JSON_OBJECT_T;
BEGIN
  -- Construct the order object
  order_json := new JSON_OBJECT_T;
  order_json.put('orderid', orderid);
  order_json.put('itemid',  itemid);
  order_json.put('deliverylocation', deliverylocation);
  order_json.put('status', 'Pending');
  order_json.put('inventoryLocation', '');
  order_json.put('suggestiveSale', '');

  -- Insert the order object
  insert_order(orderid, order_json.to_string());

  -- Send the order message
  enqueue_order_message(order_json.to_string());

  -- Commit
  commit;

  HTP.print(order_json.to_string());

  EXCEPTION
    WHEN OTHERS THEN
      HTP.print(SQLERRM);

END;
/
show errors


-- Insert order
CREATE OR REPLACE PROCEDURE insert_order(in_order_id IN VARCHAR2, in_order IN VARCHAR2)
AUTHID CURRENT_USER
IS
  order_doc             SODA_DOCUMENT_T;
  collection            SODA_COLLECTION_T;
  status                NUMBER;
  collection_name       CONSTANT VARCHAR2(20) := 'orderscollection';
  collection_metadata   CONSTANT VARCHAR2(4000) := '{"keyColumn" : {"assignmentMethod": "CLIENT"}}';
BEGIN
  -- Write the order object
  collection := DBMS_SODA.open_collection(collection_name);
  IF collection IS NULL THEN
    collection := DBMS_SODA.create_collection(collection_name, collection_metadata);
  END IF;

  order_doc := SODA_DOCUMENT_T(in_order_id, b_content => utl_raw.cast_to_raw(in_order));
  status := collection.insert_one(order_doc);
END;
/
show errors


-- Enqueue order message
CREATE OR REPLACE PROCEDURE enqueue_order_message(in_order_message IN VARCHAR2)
AUTHID CURRENT_USER
IS
   enqueue_options     dbms_aq.enqueue_options_t;
   message_properties  dbms_aq.message_properties_t;
   message_handle      RAW(16);
   message             SYS.AQ\$_JMS_TEXT_MESSAGE;
BEGIN
  message := SYS.AQ\$_JMS_TEXT_MESSAGE.construct;
  message.set_text(in_order_message);

  dbms_aq.ENQUEUE(queue_name => '$AQ_USER.$ORDER_QUEUE',
    enqueue_options    => enqueue_options,
    message_properties => message_properties,
    payload            => message,
    msgid              => message_handle);
END;
/
show errors
