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

//        https://stackoverflow.com/questions/8348427/how-to-write-update-oracle-blob-in-a-reliable-way

        System.setProperty("oracle.jdbc.fanEnabled", "false");
        PoolDataSource poolDataSource = PoolDataSourceFactory.getPoolDataSource();
        poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        poolDataSource.setURL("jdbc:oracle:thin:@sagadb2_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1");
        poolDataSource.setUser("admin");
        poolDataSource.setPassword("Welcome12345");
        Connection conn = poolDataSource.getConnection();
        System.out.println("UploadWalletToDataDumpDir conn:" + conn);
        File blob = new File("/Users/pparkins/Downloads/Wallet_sagadb1/cwallet.sso");
        FileInputStream in = new FileInputStream(blob);

// the cast to int is necessary because with JDBC 4 there is
// also a version of this method with a (int, long)
// but that is not implemented by Oracle
//        pstmt.setBinaryStream(1, in, (int)blob.length());
//
        CallableStatement cstmt = conn.prepareCall("{call write_file(?,?,?)}");
        cstmt.setString(1, "DATA_PUMP_DIR"); //'DATA_PUMP_DIR'
//        cstmt.setString("directory_name", "DATA_DUMP_DIR");
        cstmt.setString(2, "cwallet.sso");
//        cstmt.setString("file_name", "cwallet.sso");
        cstmt.setBinaryStream(3, in);
//        cstmt.setBinaryStream(3, in, (int)blob.length());
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
