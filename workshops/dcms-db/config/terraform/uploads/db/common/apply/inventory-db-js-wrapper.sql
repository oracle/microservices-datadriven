-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- add inventory - REST api
create or replace procedure add_inventory (itemid in varchar2)
authid current_user
is
  ctx dbms_mle.context_handle_t := dbms_mle.create_context();
  js_code clob := q'~
$(<./js/inventory.js)

// import itemid
const itemid = bindings.importValue("itemid");

// add inventory
addInventory(itemid);
~';
begin

  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'itemid', itemid);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', js_code);

  dbms_mle.drop_context(ctx);

exception
  when others then
    dbms_mle.drop_context(ctx);
    raise;

end;
/
show errors


-- remove inventory - REST api
create or replace procedure remove_inventory (itemid in varchar2)
authid current_user
is
  ctx dbms_mle.context_handle_t := dbms_mle.create_context();
  js_code clob := q'~
$(<./js/inventory.js)

// import itemid
const itemid = bindings.importValue("itemid");

// remove inventory
removeInventory(itemid);
~';
begin

  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'itemid', itemid);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', js_code);

  dbms_mle.drop_context(ctx);

exception
  when others then
    dbms_mle.drop_context(ctx);
    raise;

end;
/
show errors

-- get inventory - REST api
create or replace procedure get_inventory (
  itemid in varchar2,
  inventorycount out varchar2)
  authid current_user
is
  ctx dbms_mle.context_handle_t := dbms_mle.create_context();
  js_code clob := q'~
$(<./js/inventory.js)

// import itemid
const itemid = bindings.importValue("itemid");

// get the inventory count
const invCount = getInventory(itemid);

// export invCount
bindings.exportValue("invCount", invCount);
~';
begin

  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'itemid', itemid);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', js_code);

  -- handle response
  dbms_mle.import_from_mle(ctx, 'invCount', inventorycount);

  dbms_mle.drop_context(ctx);

exception
when others then
  dbms_mle.drop_context(ctx);
  raise;

end;
/
show errors

-- order message consumer - background job
create or replace procedure order_message_consumer
authid current_user
is
  ctx dbms_mle.context_handle_t := dbms_mle.create_context();
  js_code clob := q'~
$(<./js/inventory.js)

// process inventory messages
orderMessageConsumer();
~';
begin
  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', js_code);

  dbms_mle.drop_context(ctx);

exception
  when others then
    dbms_mle.drop_context(ctx);
    raise;

end;
/
show errors
