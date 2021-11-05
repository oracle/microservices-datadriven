BEGIN
  DBMS_CLOUD.GET_OBJECT(
    object_uri => 'https://objectstorage.ashburn-1.oraclecloud.com/cwallet.s',
    directory_name => 'DATA_PUMP_DIR');

  DBMS_CLOUD.CREATE_CREDENTIAL(
    credential_name => 'CRED',
    username => 'mytopicuser',
    password => 'mydbpassword');

  DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(
    db_link_name => 'ORDERTOINVENTORYLINK',
    hostname => '`grep -oP '(?<=host=).*?(?=\))' <<<"$TTNS"`',
    port => '`grep -oP '(?<=port=).*?(?=\))' <<<"$TTNS"`',
    service_name => '`grep -oP '(?<=service_name=).*?(?=\))' <<<"$TTNS"`',
    ssl_server_cert_dn => '`grep -oP '(?<=ssl_server_cert_dn=\").*?(?=\"\))' <<<"$TTNS"`',
    credential_name => 'CRED',
    directory_name => 'DATA_PUMP_DIR');
END;
/


oracle.ucp.jdbc.PoolDataSource.orderpdb.URL = jdbc:oracle:thin:/@orderpdb?TNS_ADMIN=/Users/pparkins/Downloads/ords-21/tns_admin
oracle.ucp.jdbc.PoolDataSource.orderpdb.user = admin
oracle.ucp.jdbc.PoolDataSource.orderpdb.password = WElcome12345##

FOR DBCS...  create a database link with the same name as the database it
           connects to, or set global_names=false.


CREATE DATABASE LINK ORDERTOINVENTORYLINK
    CONNECT TO ADMIN IDENTIFIED BY WElcome12345##
    USING '(DESCRIPTION=(CONNECT_TIMEOUT=5)(TRANSPORT_CONNECT_TIMEOUT=3)(RETRY_COUNT=3)(ADDRESS_LIST=(LOAD_BALANCE=on)(ADDRESS=(PROTOCOL=TCP)(HOST=129.146.161.232)(PORT=1521)))(CONNECT_DATA=(SERVICE_NAME=inventorypdb.sub09071537170.domnet.oraclevcn.com)))';