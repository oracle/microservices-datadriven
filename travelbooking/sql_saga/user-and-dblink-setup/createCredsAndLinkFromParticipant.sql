Set
ECHO ON

SET ECHO ON;


--MUST BE CAPITAL USERNAME

BEGIN
DBMS_CLOUD.DROP_CREDENTIAL(
    credential_name => 'TRAVELAGENCYADMINCRED');
END;
/
BEGIN
  DBMS_CLOUD_ADMIN.DROP_DATABASE_LINK(
    db_link_name => 'teqtesttravelagencyadmin');
END;
/

BEGIN
DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'TRAVELAGENCYADMINCRED',
    username => 'TRAVELAGENCYADMIN',
    password => 'Welcome12345');
END;
/
BEGIN
  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => 'teqtesttravelagencyadmin',
    hostname => 'adb.us-ashburn-1.oraclecloud.com',
    port => '1522',
    service_name => 'bsenjiat5lmurtq_teqtest_tp.adb.oraclecloud.com',
    ssl_server_cert_dn => 'CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US',
    credential_name => 'TRAVELAGENCYADMINCRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/
select sysdate from dual@teqtesttravelagencyadmin;


