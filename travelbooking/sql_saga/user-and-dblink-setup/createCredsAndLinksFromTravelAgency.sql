Set
ECHO ON

SET ECHO ON;

BEGIN
DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'FLIGHTADMINCRED',
    username => 'AIRLINEADMIN',
    password => 'Welcome12345');
END;
/

BEGIN
DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'HOTELADMINCRED',
    username => 'HOTELADMIN',
    password => 'Welcome12345');
END;
/

BEGIN
DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CARADMINCRED',
    username => 'CARADMIN',
    password => 'Welcome12345');
END;
/


BEGIN
  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => 'teqtest2flightadmin',
    hostname => 'adb.us-ashburn-1.oraclecloud.com',
    port => '1522',
    service_name => 'bsenjiat5lmurtq_teqtest2_tp.adb.oraclecloud.com',
    ssl_server_cert_dn => 'CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US',
    credential_name => 'FLIGHTADMINCRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/
select sysdate from dual@teqtest2flightadmin;

BEGIN
  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => 'teqtest2hoteladmin',
    hostname => 'adb.us-ashburn-1.oraclecloud.com',
    port => '1522',
    service_name => 'bsenjiat5lmurtq_teqtest2_tp.adb.oraclecloud.com',
    ssl_server_cert_dn => 'CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US',
    credential_name => 'HOTELADMINCRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/
select sysdate from dual@teqtest2hoteladmin;

BEGIN
  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => 'teqtest2caradmin',
    hostname => 'adb.us-ashburn-1.oraclecloud.com',
    port => '1522',
    service_name => 'bsenjiat5lmurtq_teqtest2_tp.adb.oraclecloud.com',
    ssl_server_cert_dn => 'CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US',
    credential_name => 'CARADMINCRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/
select sysdate from dual@teqtest2caradmin;
