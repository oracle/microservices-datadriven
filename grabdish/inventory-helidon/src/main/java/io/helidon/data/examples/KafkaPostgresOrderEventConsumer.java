package io.helidon.data.examples;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class KafkaPostgresOrderEventConsumer {

    String url = "jdbc:postgresql://localhost:5432/testdb";
    String user = "user12";
    String password = "34klq*";

    public void testConnection() {
        try (
                Connection con = DriverManager.getConnection(url, user, password);
                Statement st = con.createStatement();
                ResultSet rs = st.executeQuery("SELECT VERSION()")) {

            if (rs.next()) {
                System.out.println(rs.getString(1));
            }

        } catch (
                SQLException ex) {
            ex.printStackTrace();
        }
    }
}
