-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


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

-- get order in PL/SQL
create or replace procedure show_order_plsql (
  orderid in out varchar2,
  itemid out varchar2,
  deliverylocation out varchar2,
  status out varchar2,
  inventorylocation out varchar2,
  suggestivesale out varchar2)
  authid current_user
is
  order_jo json_object_t;
begin

  -- get the order object
  order_collection.get_order(orderid, order_jo);

  itemid :=            order_jo.get('itemid');
  deliverylocation :=  order_jo.get('deliverylocation');
  status :=            order_jo.get('status');
  inventorylocation := order_jo.get('inventorylocation');
  suggestivesale :=    order_jo.get('suggestivesale');

exception
   when others then
     rollback;
     raise;

end;
/
show errors


-- Delete all orders in PL/SQL
create or replace procedure delete_all_orders_plsql
  authid current_user
is
  order_jo json_object_t;
begin

  -- delete all the order objects
  order_collection.delete_all_orders;

  -- commit
  commit;

exception
   when others then
     rollback;
     raise;

end;
/
show errors


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
