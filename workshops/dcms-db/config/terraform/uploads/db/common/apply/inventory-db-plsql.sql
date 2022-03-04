-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- add inventory - REST api
create or replace procedure add_inventory (itemid in varchar2)
  authid current_user
is
begin
  update inventory set inventorycount=inventorycount+1 where inventoryid = itemid;
  commit;
end;
/
show errors

-- remove inventory - REST api
create or replace procedure remove_inventory (itemid in varchar2)
  authid current_user
is
begin
  update inventory set inventorycount=inventorycount+1 where inventoryid = itemid;
  commit;
end;
/
show errors

-- get inventory - REST api
create or replace procedure get_inventory (
  itemid in varchar2,
  inventorycount out varchar2)
  authid current_user
is
begin
  select inventorycount into inventorycount from inventory where inventoryid = itemid;
end;
/
show errors


-- check inventory - private
create or replace function update_inventory(in_inventory_id in varchar2) return varchar2
is
  v_inventory_location inventory.inventorylocation%type;
begin
  update inventory set inventorycount = inventorycount - 1
    where inventoryid = in_inventory_id and inventorycount > 0
    returning inventorylocation into v_inventory_location;
  if sql%rowcount = 0 then
    return 'inventorydoesnotexist';
  end if;
  return v_inventory_location;
end;
/
show errors


-- order message consumer - background job
create or replace procedure order_message_consumer
is
  order_jo json_object_t;
  inv_msg_jo json_object_t;
  order_inv_id inventory.inventoryid%type;
  order_inv_loc inventory.inventorylocation%type;
begin
  loop
    -- wait for and dequeue the next order message
    order_jo := inventory_messaging.dequeue_order_message(-1); -- wait forever

    if order_jo is null then
      rollback;
      continue;
    end if;

    -- Parse the order message
    order_inv_id := order_jo.get_string('itemid');

    -- check the inventory
    order_inv_loc := update_inventory(in_inventory_id => order_inv_id);

    -- construct the inventory message
    inv_msg_jo := new json_object_t;
    inv_msg_jo.put('orderid',           order_jo.get_string('orderid'));
    inv_msg_jo.put('itemid',            order_inv_id);
    inv_msg_jo.put('inventorylocation', order_inv_loc);
    inv_msg_jo.put('suggestiveSale',    'beer');

    -- persist the updates
    inventory_messaging.enqueue_inventory_message(inv_msg_jo);

    -- commit
    commit;

  end loop;
end;
/
show errors
