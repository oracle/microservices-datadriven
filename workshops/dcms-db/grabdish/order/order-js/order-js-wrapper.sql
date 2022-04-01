-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- order js loader
create or replace package order_js
  authid current_user
as
  function ctx return dbms_mle.context_handle_t;
end order_js;
/
show errors

create or replace package body order_js
as
  mle_ctx dbms_mle.context_handle_t := dbms_mle.create_context();
  js_eval boolean := false;
  js_code clob := q'~
$(<./order-js/order.js)
~';

  function ctx return dbms_mle.context_handle_t
  is
  begin
    if not js_eval then
      dbms_mle.eval(mle_ctx, 'JAVASCRIPT', js_code);
      js_eval := true;
    end if;
    return mle_ctx;
  end ctx;
end order_js;
/
show errors

-- preload the js
set serveroutput on
declare
  ctx dbms_mle.context_handle_t := order_js.ctx;
begin
  dbms_output.put_line('order.js loaded');
end;
/
show errors

-- place order - REST api
create or replace procedure place_order (
  orderid in out varchar2,
  itemid in out varchar2,
  deliverylocation in out varchar2,
  status out varchar2,
  inventorylocation out varchar2,
  suggestivesale out varchar2)
authid current_user
is
  ctx dbms_mle.context_handle_t := order_js.ctx;
  order_jo json_object_t;
  order_string varchar2(1000);
  js_code clob := q'~
// export order
bindings.exportValue(
  "order", 
  JSON.stringify(
    placeOrder(
      JSON.parse(
        bindings.importValue("order")))));
~';
begin

  -- construct the order object
  order_jo := new json_object_t;
  order_jo.put('orderid', orderid);
  order_jo.put('itemid',  itemid);
  order_jo.put('deliverylocation', deliverylocation);

  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'order', order_jo.to_string);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', js_code);

  -- handle response
  dbms_mle.import_from_mle(ctx, 'order', order_string);

  order_jo := json_object_t(order_string);
  orderid :=           order_jo.get_string('orderid');
  itemid :=            order_jo.get_string('itemid');
  deliverylocation :=  order_jo.get_string('deliverylocation');
  status :=            order_jo.get_string('status');
  inventorylocation := order_jo.get_string('inventorylocation');
  suggestivesale :=    order_jo.get_string('suggestivesale');

exception
  when others then
    raise;

end;
/
show errors

-- show order - REST api
create or replace procedure show_order (
  orderid in out varchar2,
  itemid out varchar2,
  deliverylocation out varchar2,
  status out varchar2,
  inventorylocation out varchar2,
  suggestivesale out varchar2)
  authid current_user
is
  ctx dbms_mle.context_handle_t := order_js.ctx;
  order_jo json_object_t;
  order_string varchar2(1000);
  js_code clob := q'~
bindings.exportValue(
  "order", 
  JSON.stringify(
    showOrder(
      bindings.importValue("orderid"))));
~';
begin
  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'orderid', orderid);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', js_code);

  -- handle response
  dbms_mle.import_from_mle(ctx, 'order', order_string);

  order_jo :=          json_object_t(order_string);
  orderid :=           order_jo.get_string('orderid');
  itemid :=            order_jo.get_string('itemid');
  deliverylocation :=  order_jo.get_string('deliverylocation');
  status :=            order_jo.get_string('status');
  inventorylocation := order_jo.get_string('inventorylocation');
  suggestivesale :=    order_jo.get_string('suggestivesale');

exception
  when others then
    raise;

end;
/
show errors

-- delete all orders - REST api
create or replace procedure delete_all_orders
authid current_user
is
  ctx dbms_mle.context_handle_t := order_js.ctx;
begin
  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', 'deleteAllOrders();');

exception
  when others then
    raise;

end;
/
show errors

-- inventory message consumer - background job
create or replace procedure inventory_message_consumer
authid current_user
is
  ctx dbms_mle.context_handle_t := order_js.ctx;
begin
  loop
    -- execute javascript'
    dbms_mle.eval(ctx, 'JAVASCRIPT', 'inventoryMessageConsumer();');
    commit;
  end loop;
exception
  when others then
    raise;

end;
/
show errors
