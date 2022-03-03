-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


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
    p_object       => 'PLACE_ORDER',
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
    p_object       => 'SHOW_ORDER',
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
    p_object       => 'DELETE_ALL_ORDERS',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'deleteallorders'
  );

  commit;
end;
/

begin
  dbms_scheduler.stop_job('order_service_plsql');
  exception
    when others then
      null;
end;
/

begin
  dbms_scheduler.drop_job('order_service_plsql');
  exception
    when others then
      null;
end;
/

begin
  dbms_scheduler.create_job (
    job_name           =>  'order_service_plsql',
    job_type           =>  'STORED_PROCEDURE',
    job_action         =>  'inventory_message_consumer',
    repeat_interval    =>  'FREQ=SECONDLY;INTERVAL=10');

--    dbms_scheduler.set_attribute (
--    'order_service_plsql', 'logging_level', dbms_scheduler.logging_full);

    dbms_scheduler.run_job(
    job_name            => 'order_service_plsql',
    use_current_session => false);
end;
/
