Set ECHO ON

alter session set container=orders;
CREATE USER ORDERUSER IDENTIFIED BY "Welcome123";
GRANT pdb_dba TO ORDERUSER;
GRANT CREATE DATABASE LINK TO ORDERUSER;
GRANT unlimited tablespace to ORDERUSER;
GRANT connect, resource TO ORDERUSER;
GRANT aq_user_role TO ORDERUSER;
GRANT EXECUTE ON sys.dbms_aqadm TO ORDERUSER;
GRANT EXECUTE ON sys.dbms_aq TO ORDERUSER;
GRANT SODA_APP to ORDERUSER;

quit;
/