-- app user and grants
create user &&app_username identified by "&&app_password";

grant unlimited tablespace to &&app_username;
grant connect, resource to &&app_username;

-- For TxEventQ
grant aq_user_role to &&app_username;
grant execute on dbms_aq to  &&app_username;
grant execute on dbms_aqadm to &&app_username;
grant select on sys.gv_$session to &&app_username;
grant select on sys.v_$session to &&app_username;
grant select on sys.gv_$instance to &&app_username;
grant select on sys.gv_$listener_network to &&app_username;
grant select on sys.dba_rsrc_plan_directives to &&app_username;
grant select on sys.gv_$pdbs to &&app_username;
exec dbms_aqadm.grant_priv_for_rm_plan('&&app_username');
commit;
