-- liquibase formatted sql

-- changeset az_admin:initial_user endDelimiter:/ runAlways:true runOnChange:true
DECLARE
    l_user      VARCHAR2(255);
    l_tblspace  VARCHAR2(255);
BEGIN
    BEGIN
        SELECT username INTO l_user FROM DBA_USERS WHERE USERNAME='USER_REPO';
    EXCEPTION WHEN no_data_found THEN
        EXECUTE IMMEDIATE 'CREATE USER "USER_REPO" IDENTIFIED BY "${userRepoPassword}"';
    END;

    EXECUTE IMMEDIATE 'ALTER USER "USER_REPO" IDENTIFIED BY "${userRepoPassword}" ACCOUNT UNLOCK';

    SELECT default_tablespace INTO l_tblspace FROM dba_users WHERE username = 'USER_REPO';

    EXECUTE IMMEDIATE 'ALTER USER "USER_REPO" QUOTA UNLIMITED ON ' || l_tblspace;
    EXECUTE IMMEDIATE 'GRANT CONNECT TO "USER_REPO"';
    EXECUTE IMMEDIATE 'GRANT RESOURCE TO "USER_REPO"';
    EXECUTE IMMEDIATE 'ALTER USER "USER_REPO" DEFAULT ROLE CONNECT,RESOURCE';
END;
/

--rollback drop user "USER_REPO" cascade;
