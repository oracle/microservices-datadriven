-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- add inventory - REST api
create or replace procedure add_inventory (
  itemid in out varchar2,
  inventorycount out varchar2)
  authid current_user
is
begin
  update inventory set inventorycount=inventorycount + 1 
    where inventoryid = itemid
    returning inventorycount into inventorycount;
  commit;
end;
/
show errors

-- remove inventory - REST api
create or replace procedure remove_inventory (
  itemid in out varchar2,
  inventorycount out varchar2)
  authid current_user
is
begin
  update inventory set inventorycount=inventorycount - 1 
    where inventoryid = itemid
    returning inventorycount into inventorycount;
  commit;
end;
/
show errors

-- get inventory - REST api
create or replace procedure get_inventory (
  itemid in out varchar2,
  inventorycount out varchar2)
  authid current_user
is
begin
  select inventorycount into inventorycount from inventory where inventoryid = itemid;
end;
/
show errors

-- fulfill order - business logic
create or replace function fulfill_order(in_order_jo in json_object_t) return json_object_t
  authid current_user
is
  inv_msg_jo json_object_t;
  v_item_id inventory.inventoryid%type;
  v_inventory_location inventory.inventorylocation%type;
begin
  v_item_id := in_order_jo.get_string('itemid');

  -- construct the inventory message
  inv_msg_jo := new json_object_t;
  inv_msg_jo.put('orderid',           in_order_jo.get_string('orderid'));
  inv_msg_jo.put('itemid',            v_item_id);
  inv_msg_jo.put('suggestiveSale',    'beer');

  update inventory set inventorycount = inventorycount - 1
    where inventoryid = v_item_id and inventorycount > 0
    returning inventorylocation into v_inventory_location;

  if sql%rowcount = 0 then
    inv_msg_jo.put('inventorylocation', 'inventorydoesnotexist');
  else
    inv_msg_jo.put('inventorylocation', v_inventory_location);
  end if;

  return inv_msg_jo;
end;
/
show errors


-- order message consumer - background job
create or replace procedure order_message_consumer
  authid current_user
is
  order_jo json_object_t;
  inv_msg_jo json_object_t;
begin
  loop
    -- wait for and dequeue the next order message
    order_jo := inventory_messaging.dequeue_order_message(-1); -- wait forever

    if order_jo is null then
      rollback;
      continue;
    end if;

    -- fulfill the order
    inv_msg_jo := fulfill_order(order_jo);

    -- send the inventory message in response
    inventory_messaging.enqueue_inventory_message(inv_msg_jo);

    -- commit
    commit;

  end loop;
end;
/
show errors
