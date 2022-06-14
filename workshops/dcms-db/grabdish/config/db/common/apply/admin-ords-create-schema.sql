-- Copyright (c) 2021 Oracle and/or its affiliates.
-- Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/


CREATE USER $ORDS_USER IDENTIFIED BY "$ORDS_PASSWORD}";
GRANT CONNECT TO $ORDS_USER;
ALTER USER $ORDS_USER PROFILE ORA_APP_PROFILE;

CREATE USER $PLGW_USER IDENTIFIED BY "$ORDS_PASSWORD}";
GRANT CONNECT TO $PLGW_USER;
ALTER USER $PLGW_USER PROFILE ORA_APP_PROFILE;


BEGIN
    ORDS_ADMIN.PROVISION_RUNTIME_ROLE (
        p_user => '$ORDS_USER',
        p_proxy_enabled_schemas => TRUE
    );
END;
/

ALTER USER $PLGW_USER GRANT CONNECT THROUGH $ORDS_USER;
BEGIN
    ORDS_ADMIN.CONFIG_PLSQL_GATEWAY (
        p_runtime_user => '$ORDS_USER',
        p_plsql_gateway_user => '$PLGW_USER'
    );
END;
/

begin
    apex_instance_admin.set_parameter(
        p_parameter => 'IMAGE_PREFIX',
        p_value     => 'https://static.oracle.com/cdn/apex/${APEX_VERSION}/' );
    commit;
end;
/
