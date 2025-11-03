-- Set as appropriate for your database.
alter session set container = freepdb1;

-- user for okafka
create user TESTUSER identified by testpwd;
grant create session to TESTUSER;
grant resource, connect, unlimited tablespace to TESTUSER;

-- okafka permissions
grant aq_user_role to TESTUSER;
grant execute on dbms_aq to  TESTUSER;
grant execute on dbms_aqadm to TESTUSER;
grant select on gv_$session to TESTUSER;
grant select on v_$session to TESTUSER;
grant select on gv_$instance to TESTUSER;
grant select on gv_$listener_network to TESTUSER;
grant select on SYS.DBA_RSRC_PLAN_DIRECTIVES to TESTUSER;
grant select on gv_$pdbs to TESTUSER;
grant select on user_queue_partition_assignment_table to TESTUSER;
exec dbms_aqadm.GRANT_PRIV_FOR_RM_PLAN('TESTUSER');
commit;

create table testuser.log (
  id number generated always as identity primary key,
  produced timestamp,
  consumed timestamp
);
