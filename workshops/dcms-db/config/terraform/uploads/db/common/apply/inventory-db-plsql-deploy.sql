-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- deploy the web interfaces
begin
  ords.enable_schema(
    p_enabled             => true,
    p_schema              => '$INVENTORY_USER',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'inventory',
    p_auto_rest_auth      => false
  );

  ords.enable_object (
    p_enabled      => true,
    p_schema       => '$INVENTORY_USER',
    p_object       => 'ADD_INVENTORY',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'addInventory'
  );

  ords.enable_object (
    p_enabled      => true,
    p_schema       => '$INVENTORY_USER',
    p_object       => 'REMOVE_INVENTORY',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'removeInventory'
  );

  ords.enable_object (
    p_enabled      => true,
    p_schema       => '$INVENTORY_USER',
    p_object       => 'GET_INVENTORY',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'getInventory'
  );

  commit;
end;
/


-- deploy the backend message consumer
declare
  job_name varchar2(50) := 'inventory_service_plsql';
begin
  begin
    dbms_scheduler.stop_job(job_name);
    exception
      when others then
        null;
  end;

  begin
    dbms_scheduler.drop_job(job_name);
    exception
      when others then
        null;
  end;

  dbms_scheduler.create_job (
    job_name           =>  job_name,
    job_type           =>  'STORED_PROCEDURE',
    job_action         =>  'order_message_consumer',
    repeat_interval    =>  'FREQ=SECONDLY;INTERVAL=10');

  dbms_scheduler.set_attribute (
    job_name, 'logging_level', dbms_scheduler.logging_full);

  dbms_scheduler.run_job(
    job_name            => job_name,
    use_current_session => false);
end;
/
