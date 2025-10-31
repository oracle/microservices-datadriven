-- Set as appropriate for your database.
alter session set container = freepdb1;

-- user for okafka
create user TESTUSER identified by testpwd;
grant create session to TESTUSER;
grant unlimited tablespace to TESTUSER;
grant connect, resource to TESTUSER;

-- okafka permissions
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
