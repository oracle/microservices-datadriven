grant connect, resource, unlimited tablespace to orderuser;
grant aq_administrator_role to orderuser;
grant JAVASYSPRIV to orderuser;
grant aq_user_role to orderuser;
grant execute on dbms_aqadm to orderuser;
grant execute on dbms_aq to orderuser;
grant execute on dbms_aqadm to orderuser;
grant execute on dbms_lock to orderuser;
grant SELECT_CATALOG_ROLE to orderuser;
execute dbms_aqadm.grant_system_privilege('ENQUEUE_ANY','orderuser',FALSE);
execute dbms_aqadm.grant_system_privilege('DEQUEUE_ANY','orderuser',FALSE);

grant connect, resource, unlimited tablespace to inventoryuser;
grant aq_administrator_role to inventoryuser;
grant JAVASYSPRIV to inventoryuser;
grant aq_user_role to inventoryuser;
grant execute on dbms_aqadm to inventoryuser;
grant execute on dbms_aq to inventoryuser;
grant execute on dbms_aqadm_sys to inventoryuser;
grant execute on dbms_lock to inventoryuser;
grant SELECT_CATALOG_ROLE to inventoryuser;
execute dbms_aqadm.grant_system_privilege('ENQUEUE_ANY','inventoryuser',FALSE);
execute dbms_aqadm.grant_system_privilege('DEQUEUE_ANY','inventoryuser',FALSE);



GRANT pdb_dba TO $U;
GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO $U;
GRANT EXECUTE ON DBMS_CLOUD TO $U;
GRANT CREATE DATABASE LINK TO $U;
GRANT unlimited tablespace to $U;
GRANT connect, resource TO $U;
GRANT aq_user_role TO $U;
GRANT EXECUTE ON sys.dbms_aqadm TO $U;
GRANT EXECUTE ON sys.dbms_aq TO $U;



Grant succeeded.


Error starting at line : 3 in command -
grant JAVASYSPRIV to orderuser
Error report -
ORA-01919: role 'JAVASYSPRIV' does not exist
01919. 00000 -  "role '%s' does not exist"
*Cause:    Role by that name does not exist.
*Action:   Verify you are using the correct role name.

Grant succeeded.


Grant succeeded.


Grant succeeded.


Error starting at line : 7 in command -
grant execute on sys.dbms_aqadm_sys to orderuser
Error report -
ORA-00942: table or view does not exist
00942. 00000 -  "table or view does not exist"
*Cause:
*Action:

Grant succeeded.


Grant succeeded.


PL/SQL procedure successfully completed.


PL/SQL procedure successfully completed.

