package AQSaga.util;

import oracle.ucp.jdbc.PoolDataSource;

import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.nio.file.Paths;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class UploadWalletToDataDumpDir {

    public static void main(String args[]) throws Exception {
        String passwordsagadb1 = "Welcome12345"; // PromptUtil.getValueFromPromptSecure("Enter password for sagadb1", null);
        String passwordsagadb2 = "Welcome12345"; // PromptUtil.getValueFromPromptSecure("Enter password for sagadb2", null);
        String TNS_ADMIN = System.getenv("TNS_ADMIN");
//        String TNS_ADMIN = Paths.get(System.getProperty("user.dir")).getParent() + "/" + "wallet";
        //link from sagadb1 to sagadb2
//        uploadWalletAndCreateDBLink(TNS_ADMIN, "ADMIN", passwordsagadb1,"jdbc:oracle:thin:@sagadb1_tp?TNS_ADMIN=" + TNS_ADMIN,
//                "PARTICIPANTADMINCRED", "ADMIN", passwordsagadb2,
//                "participantadminlink", System.getenv("sagadb2hostname"), System.getenv("sagadb2port"),
//                System.getenv("sagadb2service_name"), System.getenv("sagadb2ssl_server_cert_dn"), true);
        //link from sagadb2 to sagadb1
        uploadWalletAndCreateDBLink(TNS_ADMIN, "ADMIN", passwordsagadb2,"jdbc:oracle:thin:@sagadb2_tp?TNS_ADMIN=" + TNS_ADMIN,
                "TRAVELAGENCYADMINCRED", "ADMIN", passwordsagadb1,
                "travelagencyadminlink", System.getenv("sagadb1hostname"), System.getenv("sagadb1port"),
                System.getenv("sagadb1service_name"), System.getenv("sagadb1ssl_server_cert_dn"), false);
    }

    private static void uploadWalletAndCreateDBLink(String tnsAdmin, String localUser, String localPW, String url, String credName, String remoteUser, String remotePW,
                                                    String linkName, String linkhostname, String linkport,
                                                    String linkservice_name, String linkssl_server_cert_dn,
                                                    boolean isCoordinator) throws Exception {
        System.out.println(
                "tnsAdmin = " + tnsAdmin + "\nlocalUser = " + localUser + "\nlocalPW = " + localPW +
                        "\nurl = " + url + "\ncredName = " + credName +
                        "\nremoteUser = " + remoteUser + "\nremotePW = " + remotePW +
                        "\nlinkName = " + linkName + "\nlinkhostname = " + linkhostname + "\nlinkport = " + linkport +
                        "\nlinkservice_name = " + linkservice_name + "\nlinkssl_server_cert_dn = " + linkssl_server_cert_dn);
        System.setProperty("oracle.jdbc.fanEnabled", "false");
        PoolDataSource poolDataSource = PoolDataSourceFactory.getPoolDataSource();
        poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        poolDataSource.setURL(url);
        poolDataSource.setUser(localUser);
        poolDataSource.setPassword(localPW);
        Connection conn = poolDataSource.getConnection();
        System.out.println("Connection:" + conn + " url:" + url);
        createDBLink(tnsAdmin, url, credName, remoteUser, remotePW, linkName, linkhostname, linkport, linkservice_name, linkssl_server_cert_dn, conn);
        installSaga(conn);
        if (isCoordinator) {
            System.out.println("Creating wrappers...");
            conn.prepareStatement(OsagaInfra.createBEGINSAGAWRAPPER).execute();
            conn.prepareStatement(OsagaInfra.createEnrollParticipant).execute();
            System.out.println("Finished creating wrappers...");
        }
    }

    private static void createDBLink(String tnsAdmin, String url, String credName, String remoteUser, String remotePW,
                                     String linkName, String linkhostname, String linkport, String linkservice_name,
                                     String linkssl_server_cert_dn, Connection conn) throws FileNotFoundException, SQLException {
        File blob = new File(tnsAdmin + "/cwallet.sso");
        FileInputStream in = new FileInputStream(blob);
        CallableStatement cstmt = conn.prepareCall(OsagaInfra.write_file_sql);
        cstmt.execute();
        System.out.println("write file procedure created for url = " + url );

        cstmt = conn.prepareCall("{call write_file(?,?,?)}");
        cstmt.setString(1, "DATA_PUMP_DIR"); // "directory_name"
        cstmt.setString(2, "cwallet.sso"); // "file_name"
        cstmt.setBinaryStream(3, in); //"contents"
        cstmt.execute();
        System.out.println("wallet uploaded for url = " + url );

        PreparedStatement preparedStatement = conn.prepareStatement(OsagaInfra.CREATE_CREDENTIAL_SQL);
        preparedStatement.setString(1, credName);
        preparedStatement.setString(2, remoteUser);
        preparedStatement.setString(3, remotePW);
        preparedStatement.execute();
        System.out.println("credName created = " + credName + " from url = " + url );

        preparedStatement = conn.prepareStatement(OsagaInfra.CREATE_DBLINK_SQL);
        preparedStatement.setString(1, linkName);
        preparedStatement.setString(2, linkhostname);
        preparedStatement.setInt(3, Integer.valueOf(linkport));
        preparedStatement.setString(4, linkservice_name);
        preparedStatement.setString(5, linkssl_server_cert_dn);
        preparedStatement.setString(6, credName);
        preparedStatement.setString(7, OsagaInfra.DATA_PUMP_DIR);
        preparedStatement.execute();
        System.out.println("dblink created = " + linkName + " from url = " + url );

        preparedStatement = conn.prepareStatement("select sysdate from dual@" + linkName);
        preparedStatement.execute();
        System.out.println("select sysdate from dual@" + linkName + " was successful");
    }

    private static void installSaga(Connection conn) throws SQLException {
       conn.setAutoCommit(false);
        for (int i = 0;i<OsagaInfra.SQL.length;i++) { //14 in total
            System.out.println("install OSaga infra starting..." + i);
            conn.prepareStatement(OsagaInfra.SQL[i]).execute();
            System.out.println("install OSaga infra completed..." + i);
        }
        conn.commit();
        System.out.println("saga setup complete");
        conn.prepareStatement("grant all on dbms_saga_adm to admin").execute();
        System.out.println("grant complete");
    }


}
