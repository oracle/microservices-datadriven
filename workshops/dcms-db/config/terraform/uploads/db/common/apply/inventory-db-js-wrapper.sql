-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- inventory js loader
create or replace package inventory_js
  authid current_user
as
  function ctx return dbms_mle.context_handle_t;
end inventory_js;
/
show errors

create or replace package body inventory_js
as
  mle_ctx dbms_mle.context_handle_t := null;
  js_code clob := q'~
$(<./js/inventory.js)
~';

  function ctx return dbms_mle.context_handle_t
  is
  begin
    if mle_ctx is null then
      dbms_mle.eval(mle_ctx, 'JAVASCRIPT', js_code);
    end if;
    return mle_ctx;
  end ctx;
end inventory_js;
/
show errors

-- preload the js
set serveroutput on
declare
  ctx dbms_mle.context_handle_t := inventory_js.ctx;
begin
  dbms_output.put_line('inventory.js loaded');
end;
/
show errors

-- add inventory - REST api
create or replace procedure add_inventory (itemid in varchar2)
authid current_user
is
  ctx dbms_mle.context_handle_t := inventory_js.ctx;
begin
  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'itemid', itemid);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', 'addInventory(bindings.importValue("itemid"));');

exception
  when others then
    raise;

end;
/
show errors

-- remove inventory - REST api
create or replace procedure remove_inventory (itemid in varchar2)
authid current_user
is
  ctx dbms_mle.context_handle_t := inventory_js.ctx;
begin

  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'itemid', itemid);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', 'removeInventory(bindings.importValue("itemid"));');

exception
  when others then
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
  ctx dbms_mle.context_handle_t := inventory_js.ctx;
begin
  -- pass variables to javascript
  dbms_mle.export_to_mle(ctx, 'itemid', itemid);

  -- execute javascript
  dbms_mle.eval(ctx, 'JAVASCRIPT', 
    'bindings.exportValue("invCount", getInventory(bindings.importValue("itemid")));');

  -- handle response
  dbms_mle.import_from_mle(ctx, 'invCount', inventorycount);

exception
when others then
  raise;

end;
/
show errors

-- order message consumer - background job
create or replace procedure order_message_consumer
authid current_user
is
  ctx dbms_mle.context_handle_t := inventory_js.ctx;
begin
  loop
    -- execute javascript
    dbms_mle.eval(ctx, 'JAVASCRIPT', 'orderMessageConsumer();');
    commit;
  end loop;
exception
  when others then
    raise;

end;
/
show errors
