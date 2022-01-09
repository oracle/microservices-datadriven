package AQSaga.util;

import oracle.ucp.jdbc.PoolDataSource;

import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.io.File;
import java.io.FileInputStream;
import java.nio.file.Paths;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;

public class UploadWalletToDataDumpDir {

    public static void main(String args[]) throws Exception {
        String passwordsagadb1 = PromptUtil.getValueFromPromptSecure("Enter password for sagadb1", null);
        String passwordsagadb2 = PromptUtil.getValueFromPromptSecure("Enter password for sagadb2", null);
        String TNS_ADMIN = Paths.get(System.getProperty("user.dir")).getParent() + "/" + "wallet";

        //link from sagadb1 to sagadb2
        uploadWalletAndCreateDBLink(TNS_ADMIN, "ADMIN", passwordsagadb1,"jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=" + TNS_ADMIN,
                "PARTICIPANTADMINCRED", "ADMIN", passwordsagadb2,
                "participantadminlink", System.getenv("sagadb2hostname"), System.getenv("sagadb2port"),
                System.getenv("sagadb2service_name"), System.getenv("sagadb2ssl_server_cert_dn"));
        //link from sagadb2 to sagadb1
        uploadWalletAndCreateDBLink(TNS_ADMIN, "ADMIN", passwordsagadb2,"jdbc:oracle:thin:@sagadb2_tp?TNS_ADMIN=" + TNS_ADMIN,
                "TRAVELAGENCYADMINCRED", "ADMIN", passwordsagadb1,
                "travelagencyadminlink", System.getenv("sagadb1hostname"), System.getenv("sagadb1port"),
                System.getenv("sagadb1service_name"), System.getenv("sagadb1ssl_server_cert_dn"));
    }

    private static void uploadWalletAndCreateDBLink(String tnsAdmin, String localUser, String localPW, String url, String credName, String remoteUser, String remotePW,
                                                    String linkName, String linkhostname, String linkport,
                                                    String linkservice_name, String linkssl_server_cert_dn) throws Exception {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
        PoolDataSource poolDataSource = PoolDataSourceFactory.getPoolDataSource();
        poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        poolDataSource.setURL(url);
        poolDataSource.setUser(localUser);
        poolDataSource.setPassword(localPW);
        Connection conn = poolDataSource.getConnection();
        System.out.println("UploadWalletToDataDumpDir conn:" + conn + " url:" + url);
//        File blob = new File("/Users/pparkins/Downloads/Wallet_sagadb1/cwallet.sso");
        File blob = new File(tnsAdmin + "/cwallet.sso");
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

        preparedStatement = conn.prepareStatement("select sysdate from dual@" + linkName);
        preparedStatement.execute();
        System.out.println("select sysdate from dual@" + linkName + " was successful");

        System.out.println("install OSaga infra part1...");
        preparedStatement = conn.prepareStatement(OsagaInfra.tableCreationEtc);
        preparedStatement.execute();
        System.out.println("install OSaga infra part2...");
        preparedStatement = conn.prepareStatement(OsagaInfra.dbms_sagaPackageBody);
        preparedStatement.execute();
        System.out.println("install OSaga infra part3...");
        preparedStatement = conn.prepareStatement(OsagaInfra.dbms_saga_adm_sysPackageBody);
        preparedStatement.execute();
        System.out.println("install OSaga infra part4...");
        preparedStatement = conn.prepareStatement(OsagaInfra.drop_brokerEtc);
        preparedStatement.execute();
        System.out.println("install OSaga infra part5...");
        preparedStatement = conn.prepareStatement(OsagaInfra.connectBrokerToInqueueEtc);
        preparedStatement.execute();
        System.out.println("install OSaga infra part6...");
        preparedStatement = conn.prepareStatement(OsagaInfra.dbms_saga_sysPackageBody);
        preparedStatement.execute();
        System.out.println("install OSaga infra part7...");
        preparedStatement = conn.prepareStatement(OsagaInfra.grantSagaAdmin);
        preparedStatement.execute();
        System.out.println("install OSaga was successful");

        //todo install saga
        //todo grant all on dbms_saga_adm to admin;
    }

    static final String DATA_PUMP_DIR = "DATA_PUMP_DIR";

    //no need for this...
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
