Set
ECHO ON

SET ECHO ON;

CREATE USER travelagencyadmin IDENTIFIED BY "Welcome12345"
      DEFAULT TABLESPACE SYSTEM
      TEMPORARY TABLESPACE SYSTEM;
-- need this or graph_developer for DATA_DUMP_DIR access rights... todo restrict to just the necessary...
GRANT pdb_dba TO travelagencyadmin;

GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO travelagencyadmin;
GRANT EXECUTE ON DBMS_CLOUD TO travelagencyadmin;
GRANT CREATE DATABASE LINK TO travelagencyadmin;
GRANT unlimited tablespace to travelagencyadmin;
GRANT connect, resource TO travelagencyadmin;
GRANT aq_user_role TO travelagencyadmin;

grant resource,connect, unlimited tablespace to travelagencyadmin;
grant create any table to travelagencyadmin;
grant create any procedure to travelagencyadmin;
grant aq_administrator_role to travelagencyadmin;

GRANT EXECUTE ON sys.dbms_aqadm TO travelagencyadmin;
GRANT EXECUTE ON sys.dbms_aq TO travelagencyadmin;
GRANT ALL ON dbms_saga_adm TO travelagencyadmin;
