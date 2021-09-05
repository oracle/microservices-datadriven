BEGIN
  DBMS_CLOUD.GET_OBJECT(
    object_uri => '$(state_get CWALLET_SSO_AUTH_URL)',
    directory_name => 'DATA_PUMP_DIR');

  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED',
    username => '$TU',
    password => '$DB_PASSWORD');

  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => '$LINK',
    hostname => '`grep -oP '(?<=host=).*?(?=\))' <<<"$TTNS"`',
    port => '`grep -oP '(?<=port=).*?(?=\))' <<<"$TTNS"`',
    service_name => '`grep -oP '(?<=service_name=).*?(?=\))' <<<"$TTNS"`',
    ssl_server_cert_dn => '`grep -oP '(?<=ssl_server_cert_dn=\").*?(?=\"\))' <<<"$TTNS"`',
    credential_name => 'CRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/