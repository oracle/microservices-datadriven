Set
ECHO ON

SET ECHO ON;

CREATE USER flightadmin IDENTIFIED BY "Welcome12345"
      DEFAULT TABLESPACE SYSTEM
      TEMPORARY TABLESPACE SYSTEM;
-- need this or graph_developer for DATA_DUMP_DIR access rights... todo restrict to just the necessary...
GRANT pdb_dba TO flightadmin;

GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO flightadmin;
GRANT EXECUTE ON DBMS_CLOUD TO flightadmin;
GRANT CREATE DATABASE LINK TO flightadmin;
GRANT unlimited tablespace to flightadmin;
GRANT connect, resource TO flightadmin;
GRANT aq_user_role TO flightadmin;

grant resource,connect, unlimited tablespace to flightadmin;
grant create any table to flightadmin;
grant create any procedure to flightadmin;
grant aq_administrator_role to flightadmin;

GRANT EXECUTE ON sys.dbms_aqadm TO flightadmin;
GRANT EXECUTE ON sys.dbms_aq TO flightadmin;
GRANT ALL ON dbms_saga_adm TO flightadmin;
