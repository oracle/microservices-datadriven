-- app user and grants
create user testuser identified by testPWD12345

grant unlimited tablespace to testuser;
grant connect, resource to testuser;

-- For TxEventQ
grant aq_user_role to testuser;
grant execute on dbms_aq to  testuser;
grant execute on dbms_aqadm to testuser;
grant select on sys.gv_$session to testuser;
grant select on sys.v_$session to testuser;
grant select on sys.gv_$instance to testuser;
grant select on sys.gv_$listener_network to testuser;
grant select on sys.dba_rsrc_plan_directives to testuser;
grant select on sys.gv_$pdbs to testuser;
exec dbms_aqadm.grant_priv_for_rm_plan('testuser');
commit;