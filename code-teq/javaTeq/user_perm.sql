-- This must be executed as SYS
create user testuser identified by Welcome12345;
grant resource, connect, unlimited tablespace to testuser;
grant aq_user_role to testuser;
grant execute on dbms_aq to testuser;
grant execute on dbms_aqadm to testuser;
grant execute ON dbms_aqin TO testuser;
grant execute ON dbms_aqjms TO testuser;
commit;