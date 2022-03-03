-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


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

-- deploy the microservice
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
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'placeorder'
  );

  commit;
end;
/

begin
  ords.enable_object (
    p_enabled      => true,
    p_schema       => 'ORDERUSER',
    p_object       => 'SHOW_ORDER_PLSQL',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'showorder'
  );

  commit;
end;
/

begin
  ords.enable_object (
    p_enabled      => true,
    p_schema       => 'ORDERUSER',
    p_object       => 'DELETE_ALL_ORDERS_PLSQL',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'deleteallorders'
  );

  commit;
end;
/
