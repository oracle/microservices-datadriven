-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- deploy the web interfaces
begin
  ords.enable_schema(
    p_enabled             => false,
    p_schema              => '$ORDER_USER',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'order',
    p_auto_rest_auth      => false
  );

  ords.enable_object (
    p_enabled      => false,
    p_schema       => '$ORDER_USER',
    p_object       => 'PLACE_ORDER',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'placeorder'
  );

  ords.enable_object (
    p_enabled      => false,
    p_schema       => '$ORDER_USER',
    p_object       => 'SHOW_ORDER',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'showorder'
  );

  ords.enable_object (
    p_enabled      => false,
    p_schema       => '$ORDER_USER',
    p_object       => 'DELETE_ALL_ORDERS',
    p_object_type  => 'PROCEDURE',
    p_object_alias => 'deleteallorders'
  );

  commit;
end;
/


-- deploy the backend message consumer
declare
  job_name varchar2(50) := 'order_service';
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
end;
/

select job_name, state, logging_level from USER_SCHEDULER_JOBS;