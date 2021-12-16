Set
ECHO ON

SET ECHO ON;

CREATE USER hoteladmin IDENTIFIED BY "Welcome12345"
      DEFAULT TABLESPACE SYSTEM
      TEMPORARY TABLESPACE SYSTEM;
-- need this or graph_developer for DATA_DUMP_DIR access rights... todo restrict to just the necessary...
GRANT pdb_dba TO hoteladmin;

GRANT EXECUTE ON DBMS_CLOUD_ADMIN TO hoteladmin;
GRANT EXECUTE ON DBMS_CLOUD TO hoteladmin;
GRANT CREATE DATABASE LINK TO hoteladmin;
GRANT unlimited tablespace to hoteladmin;
GRANT connect, resource TO hoteladmin;
GRANT aq_user_role TO hoteladmin;

grant resource,connect, unlimited tablespace to hoteladmin;
grant create any table to hoteladmin;
grant create any procedure to hoteladmin;
grant aq_administrator_role to hoteladmin;

GRANT EXECUTE ON sys.dbms_aqadm TO hoteladmin;
GRANT EXECUTE ON sys.dbms_aq TO hoteladmin;
GRANT ALL ON dbms_saga_adm TO hoteladmin;
