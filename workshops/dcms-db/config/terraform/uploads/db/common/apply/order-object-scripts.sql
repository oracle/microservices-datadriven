-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- order_collection package
create or replace package order_collection
  authid current_user
as
  procedure insert_order (in_order in json_object_t);
  procedure create_collection;
  procedure drop_collection;
end order_collection;
/
show errors

create or replace package body order_collection
as
  -- Private constants
  collection_metadata   constant varchar2(4000) := '{"keyColumn" : {"assignmentMethod": "CLIENT"}}';
  collection_name       constant nvarchar2(20) := 'orderscollection';

  function get_collection return soda_collection_t
  is
  begin
    return dbms_soda.open_collection(collection_name);
  end get_collection;

  procedure insert_order (in_order in json_object_t)
  is
    order_doc   soda_document_t;
    status      number;
    collection  soda_collection_t;
  begin
    -- write the order object
    order_doc := soda_document_t(in_order.get_string('orderid'), in_order.to_blob);
    dbms_output.put_line(in_order.get_string('orderid'));
    collection := get_collection;
    status := collection.insert_one(order_doc);
  end insert_order;

  procedure create_collection
  is
    collection  soda_collection_t;
  begin
  dbms_output.put_line(collection_name || ' ' || collection_metadata);

    collection := dbms_soda.create_collection(collection_name => collection_name, metadata => collection_metadata);
  end create_collection;

  procedure drop_collection
  is
    status number;
  begin
    status := dbms_soda.drop_collection(collection_name => collection_name);
  end drop_collection;

end order_collection;
/
show errors


-- order_messaging package
create or replace package order_messaging
  authid current_user
as
  procedure enqueue_order_message (in_order in json_object_t);
end order_messaging;
/
show errors

create or replace package body order_messaging
as
  -- Private constants
  order_queue_name      constant varchar2(100) := '$AQ_USER.$ORDER_QUEUE';

  -- enqueue order message
  procedure enqueue_order_message(in_order in json_object_t)
  is
     enqueue_options     dbms_aq.enqueue_options_t;
     message_properties  dbms_aq.message_properties_t;
     message_handle      raw(16);
     message             sys.aq\$_jms_text_message;
  begin
    message := sys.aq\$_jms_text_message.construct;
    message.set_text(in_order.to_string);

    dbms_aq.enqueue(queue_name => order_queue_name,
      enqueue_options    => enqueue_options,
      message_properties => message_properties,
      payload            => message,
      msgid              => message_handle);
  end enqueue_order_message;

end order_messaging;
/
show errors


-- place order in PL/SQL
create or replace procedure place_order_plsql (
  orderid in out varchar2,
  itemid in out varchar2,
  deliverylocation in out varchar2,
  status out varchar2,
  inventorylocation out varchar2,
  suggestivesale out varchar2)
  authid current_user
is
  order_jo json_object_t;
begin
  status := 'pending';
  inventorylocation := '';
  suggestivesale := '';

  -- construct the order object
  order_jo := new json_object_t;
  order_jo.put('orderid', orderid);
  order_jo.put('itemid',  itemid);
  order_jo.put('deliverylocation', deliverylocation);
  order_jo.put('status', status);
  order_jo.put('inventorylocation', inventorylocation);
  order_jo.put('suggestivesale', suggestivesale);

  -- insert the order object
  order_collection.insert_order(order_jo);

  -- send the order message
  order_messaging.enqueue_order_message(order_jo);

  -- commit
  commit;

exception
   when others then
     rollback;
     raise;

end;
/
show errors


-- place order using mle javascript
create or replace procedure place_order_js (
  orderid in out varchar2,
  itemid in out varchar2,
  deliverylocation in out varchar2,
  status out varchar2,
  inventorylocation out varchar2,
  suggestivesale out varchar2)
authid current_user
is
  ctx dbms_mle.context_handle_t := dbms_mle.create_context();
  js_code clob := q'~
    var oracledb = require("mle-js-oracledb");
    var bindings = require("mle-js-bindings");
    var conn = oracledb.defaultConnection();
    try {
      // construct the order object
      const order = {
        orderid: bindings.importValue("orderid"),
        itemid: bindings.importValue("itemid"),
        deliverylocation: bindings.importValue("deliverylocation"),
        status: "pending",
        inventorylocation: "",
        suggestivesale: ""
      }

      // insert the order object
      insert_order(conn, order);

      // send the order message
      enqueue_order_message(conn, order);

      // commit
      conn.commit;

      // output order
      bindings.exportValue("status", order.status);
      bindings.exportValue("inventorylocation", "blah");
      bindings.exportValue("suggestivesale", order.suggestivesale);

    } catch(error) {
      conn.rollback;
      throw error;
    }

    function insert_order(conn, order) {
        conn.execute( "begin order_collection.insert_order(json_object_t(:1)); end;", [JSON.stringify(order)]);
    }

    function enqueue_order_message(conn, order) {
        conn.execute( "begin order_messaging.enqueue_order_message(json_object_t(:1)); end;", [JSON.stringify(order)]);
    }
   ~';
begin
  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'orderid', orderid);
  dbms_mle.export_to_mle(ctx, 'itemid', itemid);
  dbms_mle.export_to_mle(ctx, 'deliverylocation', deliverylocation);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', js_code);

  -- handle response
  dbms_mle.import_from_mle(ctx, 'status', status);
  dbms_mle.import_from_mle(ctx, 'inventorylocation', inventorylocation);
  dbms_mle.import_from_mle(ctx, 'suggestivesale', suggestivesale);

  dbms_mle.drop_context(ctx);

exception
  when others then
    dbms_mle.drop_context(ctx);
    raise;

end;
/
show errors

-- Create the order collection
begin
  order_collection.create_collection;
end;
/


begin
  ords.enable_schema(
    p_enabled             => true,
    p_schema              => 'ORDERUSER',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'order',
    p_auto_rest_auth      => false
  );

  commit;
end;
/

begin
  ords.enable_object (
    p_enabled      => true,
    p_schema       => 'ORDERUSER',
    p_object       => 'PLACE_ORDER_PLSQL',
    p_object_type  => 'procedure',
    p_object_alias => 'placeorder'
  );

  commit;
end;
/
