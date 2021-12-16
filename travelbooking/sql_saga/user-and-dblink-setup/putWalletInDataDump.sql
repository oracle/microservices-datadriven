Set
ECHO ON

SET ECHO ON;

BEGIN
 DBMS_CLOUD.GET_OBJECT(
    object_uri => 'https://objectstorage.us-ashburn-1.oraclecloud.com/p/USDvIeDBDr9p4idLUD4AR_nAzugKYIIDapdru7SoHbqm8ThHSMVCP7Icmer6HMkv/n/maacloud/b/paul/o/cwallet.sso',
    directory_name => 'DATA_PUMP_DIR');
-- or directory_name => 'dblink_wallet_dir'
END;
/