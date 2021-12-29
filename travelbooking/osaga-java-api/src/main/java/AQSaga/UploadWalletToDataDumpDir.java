package AQSaga;

import oracle.ucp.jdbc.PoolDataSource;

import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.io.File;
import java.io.FileInputStream;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Types;

public class UploadWalletToDataDumpDir {

    public static void main(String args[]) throws Exception {
        uploadWallet("jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1");
        uploadWallet("jdbc:oracle:thin:@sagadb2_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1");
    }

    private static void uploadWallet(String url) throws Exception {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
        PoolDataSource poolDataSource = PoolDataSourceFactory.getPoolDataSource();
        poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        poolDataSource.setURL(url);
        poolDataSource.setUser("admin");
        poolDataSource.setPassword("Welcome12345");
        Connection conn = poolDataSource.getConnection();
        System.out.println("UploadWalletToDataDumpDir conn:" + conn + " url:" + url);
        File blob = new File("/Users/pparkins/Downloads/Wallet_sagadb1/cwallet.sso");
        FileInputStream in = new FileInputStream(blob);
        CallableStatement cstmt = conn.prepareCall("{call write_file(?,?,?)}");
        cstmt.setString(1, "DATA_PUMP_DIR"); // "directory_name"
        cstmt.setString(2, "cwallet.sso"); // "file_name"
        cstmt.setBinaryStream(3, in); //"contents"
        cstmt.execute();
        System.out.println("UploadWalletToDataDumpDir wallet uploaded");
    }

/**
 https://stackoverflow.com/questions/70400087/how-to-upload-a-regular-file-eg-cwallet-sso-to-data-pump-dir-in-oracle-db/70455324#70455324
    CREATE PROCEDURE write_file(
            directory_name   IN  VARCHAR2,
            file_name        IN  VARCHAR2,
            contents         IN  BLOB
    )
    IS
    l_file      UTL_FILE.file_type;
    l_data_len  INTEGER;
    l_buffer    RAW(32000);
    l_pos       INTEGER := 1;
    l_amount    INTEGER := 32000;
    BEGIN
    -- Get the data length to write
    l_data_len := DBMS_LOB.getlength(contents);

    -- Write the contents to local file
    l_file := UTL_FILE.FOPEN(directory_name, file_name, 'wb', l_amount);
    WHILE l_pos < l_data_len
    LOOP
      DBMS_LOB.read(contents, l_amount, l_pos, l_buffer);
      UTL_FILE.PUT_RAW(l_file, l_buffer, TRUE);
    l_pos := l_pos + l_amount;
    END LOOP;
    UTL_FILE.FCLOSE(l_file);
    EXCEPTION
    WHEN OTHERS THEN
      UTL_FILE.FCLOSE(l_file);
    RAISE;
    END write_file;
*/



}
