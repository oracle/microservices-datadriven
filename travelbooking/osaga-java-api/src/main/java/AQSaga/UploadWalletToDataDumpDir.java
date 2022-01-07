package AQSaga;

import oracle.ucp.jdbc.PoolDataSource;

import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.io.File;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Types;

public class UploadWalletToDataDumpDir {

    public static void main(String args[]) throws Exception {
        byte[] bytes = AQjmsSagaUtils.parseHexBinary("4434444630333636413534434339463445303533393531383030304141323335");
        // D4DF0366A54CC9F4E0539518000AA235
        System.out.println("UploadWalletToDataDumpDir.main" + new String(bytes, StandardCharsets.UTF_8));
    }

    public static void main0(String args[]) throws Exception {
        uploadWallet("jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1",
                "PARTICIPANTADMINCRED", "ADMIN", "Welcome12345",
                "participantadminlink", "adb.us-phoenix-1.oraclecloud.com", "1522",
                "fcnesu1k4xmzwf1_sagadb2_tp.adb.oraclecloud.com",
                "CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US");
        uploadWallet("jdbc:oracle:thin:@sagadb2_tp?TNS_ADMIN=/Users/pparkins/Downloads/Wallet_sagadb1",
                "TRAVELAGENCYADMINCRED", "ADMIN", "Welcome12345",
                "travelagencyadminlink", "adb.us-phoenix-1.oraclecloud.com", "1522",
                "fcnesu1k4xmzwf1_sagadb1_tp.adb.oraclecloud.com",
                "CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US");
    }

    private static void uploadWallet(String url, String credName, String remoteUser, String remotePW,
                                     String linkName, String linkhostname, String linkport,
                                     String linkservice_name, String linkssl_server_cert_dn) throws Exception {
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
        CallableStatement cstmt = conn.prepareCall(write_file_sql);
        cstmt.execute();
        System.out.println("write file procedure created for url = " + url );

        cstmt = conn.prepareCall("{call write_file(?,?,?)}");
        cstmt.setString(1, "DATA_PUMP_DIR"); // "directory_name"
        cstmt.setString(2, "cwallet.sso"); // "file_name"
        cstmt.setBinaryStream(3, in); //"contents"
        cstmt.execute();
        System.out.println("wallet uploaded for url = " + url );

        PreparedStatement preparedStatement1 = conn.prepareStatement(CREATE_CREDENTIAL_SQL);
        preparedStatement1.setString(1, credName);
        preparedStatement1.setString(2, remoteUser);
        preparedStatement1.setString(3, remotePW);
        preparedStatement1.execute();
        System.out.println("credName created = " + credName + " from url = " + url );

        PreparedStatement preparedStatement = conn.prepareStatement(CREATE_DBLINK_SQL);
        preparedStatement.setString(1, linkName);
        preparedStatement.setString(2, linkhostname);
        preparedStatement.setInt(3, Integer.valueOf(linkport));
        preparedStatement.setString(4, linkservice_name);
        preparedStatement.setString(5, linkssl_server_cert_dn);
        preparedStatement.setString(6, credName);
        preparedStatement.setString(7, DATA_PUMP_DIR);
        preparedStatement.execute();
        System.out.println("dblink created = " + linkName + " from url = " + url );
    }

    static final String DATA_PUMP_DIR = "DATA_PUMP_DIR";

    static final String GET_OBJECT_CWALLETSSO_DATA_PUMP_DIR = "BEGIN " +
            "DBMS_CLOUD.GET_OBJECT(" +
            "object_uri => ?, " +
            "directory_name => ?); " +
            "END;";

    static final String DROP_CREDENTIAL_SQL = "BEGIN " +
            "DBMS_CLOUD.DROP_CREDENTIAL(" +
            "credential_name => ?" +
            ");" +
            "END;";

    static final String CREATE_CREDENTIAL_SQL = " BEGIN" +
            "  DBMS_CLOUD.CREATE_CREDENTIAL(" +
            "  credential_name => ?," +
            "  username => ?," +
            "  password => ?" +
            "  );" +
            " END;";

    static final String CREATE_DBLINK_SQL = "BEGIN " +
            "DBMS_CLOUD_ADMIN.CREATE_DATABASE_LINK(" +
            "db_link_name => ?," +
            "hostname => ?," +
            "port => ?," +
            "service_name => ?," +
            "ssl_server_cert_dn => ?," +
            "credential_name => ?," +
            "directory_name => ?);" +
            "END;";

    static final  String write_file_sql = "CREATE OR REPLACE PROCEDURE write_file( " +
            "            directory_name   IN  VARCHAR2, " +
            "            file_name        IN  VARCHAR2, " +
            "            contents         IN  BLOB " +
            "    ) " +
            "    IS " +
            "    l_file      UTL_FILE.file_type; " +
            "    l_data_len  INTEGER; " +
            "    l_buffer    RAW(32000); " +
            "    l_pos       INTEGER := 1; " +
            "    l_amount    INTEGER := 32000; " +
            "    BEGIN " +
            "    l_data_len := DBMS_LOB.getlength(contents); " +
            "    l_file := UTL_FILE.FOPEN(directory_name, file_name, 'wb', l_amount); " +
            "    WHILE l_pos < l_data_len " +
            "    LOOP " +
            "      DBMS_LOB.read(contents, l_amount, l_pos, l_buffer); " +
            "      UTL_FILE.PUT_RAW(l_file, l_buffer, TRUE); " +
            "    l_pos := l_pos + l_amount; " +
            "    END LOOP; " +
            "    UTL_FILE.FCLOSE(l_file); " +
            "    EXCEPTION " +
            "    WHEN OTHERS THEN " +
            "      UTL_FILE.FCLOSE(l_file); " +
            "    RAISE; " +
            "    END write_file;";


}
