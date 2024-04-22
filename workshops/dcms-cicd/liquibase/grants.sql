-- liquibase formatted sql

-- changeset gotsysdba:grant_${schema} context:admin
ALTER USER "${schema}" QUOTA UNLIMITED ON "DATA";
GRANT CREATE SESSION TO "${schema}";
GRANT CREATE TABLE TO "${schema}";
GRANT CREATE CLUSTER TO "${schema}";
GRANT CREATE SYNONYM TO "${schema}";
GRANT CREATE VIEW TO "${schema}";
GRANT CREATE SEQUENCE TO "${schema}";
GRANT CREATE PROCEDURE TO "${schema}";
GRANT CREATE TRIGGER TO "${schema}";
GRANT CREATE MATERIALIZED VIEW TO "${schema}";
GRANT CREATE TYPE TO "${schema}";
GRANT CREATE OPERATOR TO "${schema}";
GRANT CREATE INDEXTYPE TO "${schema}";
GRANT CREATE DIMENSION TO "${schema}";
GRANT CREATE JOB TO "${schema}";

--rollback ALTER USER "${schema}" QUOTA 0 ON "DATA";
--rollback REVOKE CREATE SESSION FROM "${schema}";
--rollback REVOKE CREATE TABLE FROM "${schema}";
--rollback REVOKE CREATE CLUSTER FROM "${schema}";
--rollback REVOKE CREATE SYNONYM FROM "${schema}";
--rollback REVOKE CREATE VIEW FROM "${schema}";
--rollback REVOKE CREATE SEQUENCE FROM "${schema}";
--rollback REVOKE CREATE PROCEDURE FROM "${schema}";
--rollback REVOKE CREATE TRIGGER FROM "${schema}";
--rollback REVOKE CREATE MATERIALIZED VIEW FROM "${schema}";
--rollback REVOKE CREATE TYPE FROM "${schema}";
--rollback REVOKE CREATE OPERATOR FROM "${schema}";
--rollback REVOKE CREATE INDEXTYPE FROM "${schema}";
--rollback REVOKE CREATE DIMENSION FROM "${schema}";
--rollback REVOKE CREATE JOB FROM "${schema}";
