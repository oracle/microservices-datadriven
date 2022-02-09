-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
set echo on

declare
  username  varchar2(30) := '&1' ;
  password  varchar2(30) := '&2' ;

begin
    --- USER SQL
    CREATE USER username IDENTIFIED BY password  ;
    
    --- GRANT User permissions.
    GRANT pdb_dba TO username;
    GRANT CREATE SESSION TO username;
    GRANT RESOURCE TO username;
    GRANT CONNECT TO username;
    GRANT EXECUTE ANY PROCEDURE TO username;
    GRANT CREATE DATABASE LINK TO username;
    GRANT UNLIMITED TABLESPACE TO username;
    
    --- GRANT AQ
    GRANT AQ_ADMINISTRATOR_ROLE TO username;
    GRANT AQ_USER_ROLE TO username;
    GRANT SELECT_CATALOG_ROLE TO username;
    GRANT EXECUTE ON DBMS_AQADM TO username;
    GRANT EXECUTE on DBMS_AQ TO username;
    GRANT EXECUTE on DBMS_AQIN TO username;
    GRANT EXECUTE on DBMS_AQJMS TO username;
    GRANT EXECUTE ON sys.dbms_aqadm TO username;
    GRANT EXECUTE ON sys.dbms_aq TO username;
    GRANT EXECUTE ON sys.dbms_aqin TO username;
    GRANT EXECUTE ON sys.dbms_aqjms TO username;
    
    --- Cloud
    GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO username;
    GRANT EXECUTE ON DBMS_CLOUD TO username;
end;
/
exit;