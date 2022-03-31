-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


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
  order_jo json_object_t := new json_object_t;
begin

  -- get the order object
  order_jo := order_collection.get_order(orderid);

  itemid :=            order_jo.get_string('itemid');
  deliverylocation :=  order_jo.get_string('deliverylocation');
  status :=            order_jo.get_string('status');
  inventorylocation := order_jo.get_string('inventorylocation');
  suggestivesale :=    order_jo.get_string('suggestivesale');

exception
   when others then
     rollback;
     raise;

end;
/
show errors


-- delete all orders - REST api
create or replace procedure delete_all_orders
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

-- inventory message consumer - background job
create or replace procedure inventory_message_consumer
  authid current_user
is
  order_jo json_object_t;
  inv_msg_jo json_object_t;
begin
  loop
    -- wait for and dequeue the next order message
    inv_msg_jo := order_messaging.dequeue_inventory_message(-1); -- wait forever

    if inv_msg_jo is null then
      rollback;
      continue;
    end if;

    -- get the existing order
    order_jo := order_collection.get_order(inv_msg_jo.get_string('orderid'));

    -- update the order based on inv message
    if inv_msg_jo.get_string('inventorylocation') = 'inventorydoesnotexist' then
      order_jo.put('status', 'failed inventory does not exist');
    else
      order_jo.put('status', 'success inventory exists');
      order_jo.put('inventorylocation', inv_msg_jo.get_string('inventorylocation'));
      order_jo.put('suggestivesale', inv_msg_jo.get_string('suggestiveSale'));
    end if;

    -- persist the updates
    order_collection.update_order(order_jo);

    -- commit
    commit;

  end loop;
end;
/
show errors
