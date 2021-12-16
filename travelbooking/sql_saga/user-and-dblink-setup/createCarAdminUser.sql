Set
ECHO ON

SET ECHO ON;

CREATE USER caradmin IDENTIFIED BY "Welcome12345"
      DEFAULT TABLESPACE SYSTEM
      TEMPORARY TABLESPACE SYSTEM;
-- need this or graph_developer for DATA_DUMP_DIR access rights... todo restrict to just the necessary...
GRANT pdb_dba TO caradmin;

GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO caradmin;
GRANT EXECUTE ON DBMS_CLOUD TO caradmin;
GRANT CREATE DATABASE LINK TO caradmin;
GRANT unlimited tablespace to caradmin;
GRANT connect, resource TO caradmin;
GRANT aq_user_role TO caradmin;

grant resource,connect, unlimited tablespace to caradmin;
grant create any table to caradmin;
grant create any procedure to caradmin;
grant aq_administrator_role to caradmin;

GRANT EXECUTE ON sys.dbms_aqadm TO caradmin;
GRANT EXECUTE ON sys.dbms_aq TO caradmin;
GRANT ALL ON dbms_saga_adm TO caradmin;
