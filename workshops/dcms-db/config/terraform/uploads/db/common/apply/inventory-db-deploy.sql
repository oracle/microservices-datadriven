-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


-- enable ORDS for this schema
begin
  ords.enable_schema(
    p_enabled             => true,
    p_schema              => '$INVENTORY_USER',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'inventory',
    p_auto_rest_auth      => false
  );
  commit;
end;
/

-- define roles and privileges
begin
  ords.delete_privilege (
    p_name => 'inventory_mgmt'
  );

  commit;
end;
/

begin
  ords.delete_role(
    p_role_name => 'inventory_user'
  );

  commit;
end;
/

begin
  ords.create_role(
    p_role_name => 'inventory_user'
  );

  commit;
end;
/

declare
  l_roles_arr    owa.vc_arr;
  l_patterns_arr owa.vc_arr;
begin
  l_roles_arr(1)    := 'inventory_user';
  l_patterns_arr(1) := '/addInventory/';
  l_patterns_arr(2) := '/removeInventory/';
  l_patterns_arr(3) := '/getInventory/';

  ords.define_privilege (
    p_privilege_name => 'inventory_mgmt',
    p_roles          => l_roles_arr,
    p_patterns       => l_patterns_arr,
    p_label          => 'inventory mgmt',
    p_description    => 'allow access to inventory management interfaces'
  );

  commit;
end;
/

-- deploy the web interfaces
begin
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


SET LINESIZE 200
COLUMN parsing_schema FORMAT A20
COLUMN parsing_object FORMAT A20
COLUMN object_alias FORMAT A20
COLUMN type FORMAT A20
COLUMN status FORMAT A10

SELECT parsing_schema,
       parsing_object,
       object_alias,
       type,
       status
FROM   user_ords_enabled_objects
ORDER BY 1, 2;


-- deploy the backend message consumer
declare
  job_name varchar2(50) := 'inventory_service';
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

select job_name, state, logging_level from USER_SCHEDULER_JOBS;
