-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
set echo off

DECLARE
  my_user  varchar2(30) := '&1' ;
  my_password  varchar2(30) := '&2' ;

BEGIN
    --- USER SQL
    EXECUTE IMMEDIATE 'CREATE USER '||my_user||' IDENTIFIED BY '||my_password;

    --- GRANT User permissions.
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO '||my_user;
    EXECUTE IMMEDIATE 'GRANT pdb_dba TO '||my_user;
    EXECUTE IMMEDIATE 'GRANT RESOURCE TO '||my_user;
    EXECUTE IMMEDIATE 'GRANT CONNECT TO '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ANY PROCEDURE TO '||my_user;
    EXECUTE IMMEDIATE 'GRANT CREATE DATABASE LINK TO '||my_user;
    EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO '||my_user;

    --- GRANT AQ
    EXECUTE IMMEDIATE 'GRANT AQ_ADMINISTRATOR_ROLE TO '||my_user;
    EXECUTE IMMEDIATE 'GRANT AQ_USER_ROLE TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT SELECT_CATALOG_ROLE TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON DBMS_AQADM TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE on DBMS_AQ TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE on DBMS_AQIN TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE on DBMS_AQJMS TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_aqadm TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_aq TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_aqin TO  '||my_user;
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON sys.dbms_aqjms TO  '||my_user;
    
END;
/
exit;