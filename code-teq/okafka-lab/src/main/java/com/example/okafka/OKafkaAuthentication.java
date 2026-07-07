package com.example.okafka;

import java.util.Properties;

import static com.example.okafka.OKafka.getEnv;

public class OKafkaAuthentication {
    // For this example, we'll configure our authentication parameters with environment variables.
    // The security.protocol property supports PLAINTEXT (insecure) and SSL (secure) authentication.
    private static final String securityProtocol = getEnv("SECURITY_PROTOCOL", "PLAINTEXT");

    // For PLAINTEXT authentication, provide the HOSTNAME:PORT as the bootstrap.servers property.
    private static final String bootstrapServers = getEnv("BOOTSTRAP_SERVERS", "localhost:9092");

    // The TNS Admin alias / Oracle Database Service name.
    private static final String tnsAdmin = getEnv("TNS_ADMIN", "freepdb1");

    // The directory containing the database wallet. For PLAINTEXT, this directory need only
    // contain an ojdbc.properties file with the "user" and "password" properties configured.
    private static final String walletDir = getEnv("WALLET_DIR", "./wallet");

    /**
     * Create a Java Properties object for Oracle AI Database OKafka connection.
     * Configure using the SECURITY_PROTOCOL, BOOTSTRAP_SERVERS, TNS_ADMIN, and WALLET_DIR environment variables.
     * @return configured Properties object.
     */
    public static Properties getAuthenticationProperties() {
        // Just like kafka-clients, we can use a Java Properties object to configure connection parameters.
        Properties props = new Properties();

        // oracle.service.name is a custom property to configure the Database service name.
        props.put("oracle.service.name", tnsAdmin);
        // oracle.net.tns_admin is a custom property to configure the directory containing Oracle Database connection files.
        // If you are using mTLS authentication, client certificates must be present in this directory.
        props.put("oracle.net.tns_admin", walletDir);
        // security.protocol is a standard Kafka property, set to PLAINTEXT or SSL for Oracle Database.
        // (SASL is not supported with Oracle Database).
        props.put("security.protocol", securityProtocol);
        if (securityProtocol.equals("SSL")) {
            // For SSL authentication, pass the TNS alias (such as "mydb_tp") to be used from the tnsnames.ora file
            // found in the WALLET_DIR directory.
            props.put("tns.alias", tnsAdmin);
        } else {
            // For PLAINTEXT authentication, we provide the database URL in the format
            // HOSTNAME:PORT as the bootstrap.servers property.
            props.put("bootstrap.servers", bootstrapServers);
        }

        return props;
    }
}
