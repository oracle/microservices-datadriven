package oracle.wallet.test;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.SQLException;

public class JdbcWalletConnectionTest {
    private static final Logger LOGGER = LoggerFactory.getLogger(JdbcWalletConnectionTest.class);

    static {
        System.setProperty("oracle.jdbc.fanEnabled", "false");
    }
    public static void main(@NotNull String args[]) throws Exception {
        LOGGER.info("Running the main method");
        PoolDataSource poolDataSource = PoolDataSourceFactory.getPoolDataSource();
        poolDataSource.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        String url = args[0];
        String user = args[1];

        LOGGER.info("URL: {}", url);
        LOGGER.info("User: {}", user);

        poolDataSource.setURL(url);
        poolDataSource.setUser(user);

        Connection conn = null;
        try {
            System.out.println("Attempt connection for url:" + url + " user:" + user);
            conn = poolDataSource.getConnection();
            System.out.println("Connection:" + conn + " url:" + url);
        } catch (SQLException sqlex) {
            System.out.println("Connection fail");
        } finally {
            if (conn != null)
                conn.close();
        }

        conn = null;
    }
}