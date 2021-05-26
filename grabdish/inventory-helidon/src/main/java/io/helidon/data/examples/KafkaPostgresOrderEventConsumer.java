package io.helidon.data.examples;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;


import java.util.Properties;
import java.util.Arrays;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.ConsumerRecord;

public class KafkaPostgresOrderEventConsumer {

    String url = "jdbc:postgresql://postgres.msdataworkshop:5432/postgresdb";
    String user = "postgresadmin";
    String password = "admin123";

    public void testConnection() {
        try (
                Connection con = DriverManager.getConnection(url, user, password);
                Statement st = con.createStatement();
                ResultSet rs = st.executeQuery("SELECT VERSION()")) {
            if (rs.next()) {
                System.out.println("KafkaPostgresOrderEventConsumer  testConnection() con:" + con);
                System.out.println(rs.getString(1));
            }
        } catch (
                SQLException ex) {
            ex.printStackTrace();
        }
        placeOrder();
    }

    public void placeOrder() {
        System.out.println("KafkaPostgresOrderEventConsumer  about to listen for messages...");
//            String topicName = "sample.topic:1:1";
        String topicName = "sample.topic";
        Properties props = new Properties();
        props.put("bootstrap.servers", "kafka-service:9092");
        props.put("group.id", "test");
        props.put("enable.auto.commit", "true");
        props.put("auto.commit.interval.ms", "1000");
        props.put("session.timeout.ms", "30000");
        props.put("key.deserializer",
                "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer",
                "org.apache.kafka.common.serialization.StringDeserializer");
        KafkaConsumer<String, String> consumer = new KafkaConsumer
                <String, String>(props);
        System.out.println("KafkaPostgresOrderEventConsumer  consumer:" + consumer);
        consumer.subscribe(Arrays.asList(topicName));
        System.out.println("Subscribed to topic " + topicName);
        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(100);
            for (ConsumerRecord<String, String> record : records)
                System.out.printf("message offset = %d, key = %s, value = %s\n",
                        record.offset(), record.key(), record.value());
        }
    }
}
