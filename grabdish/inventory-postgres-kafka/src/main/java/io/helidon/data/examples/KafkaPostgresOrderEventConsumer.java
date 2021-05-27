/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.lang.IllegalStateException;
import java.sql.*;
import java.sql.Connection;
import java.util.Arrays;
import java.util.Properties;


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
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

public class KafkaPostgresOrderEventConsumer implements Runnable {

    private static final String DECREMENT_BY_ID =
            "update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";
    InventoryResource inventoryResource;

    public KafkaPostgresOrderEventConsumer(InventoryResource inventoryResource) {
        this.inventoryResource = inventoryResource;
    }

    @Override
    public void run() {
        System.out.println("Receive messages...");
        try {
            listenForOrderEvents();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void listenForOrderEvents() throws Exception {
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
            for (ConsumerRecord<String, String> record : records) {
                System.out.printf("message offset = %d, key = %s, value = %s\n",
                        record.offset(), record.key(), record.value());  String txt = record.value();
                System.out.println("txt " + txt);
                Order order = JsonUtils.read(txt, Order.class);
                System.out.print(" orderid:" + order.getOrderid());
                System.out.print(" itemid:" + order.getItemid());
                updateDataAndSendEventOnInventory(order.getOrderid(), order.getItemid());
            }
        }
    }



    private void updateDataAndSendEventOnInventory( String orderid, String itemid) throws Exception {
        String inventorylocation = evaluateInventory(itemid);
        Inventory inventory = new Inventory(orderid, itemid, inventorylocation, "beer"); //static suggestiveSale - represents an additional service/event
        String jsonString = JsonUtils.writeValueAsString(inventory);
        System.out.println("send inventory status message... jsonString:" + jsonString );
    /**
        Topic inventoryTopic = session.getTopic(InventoryResource.inventoryuser, InventoryResource.inventoryQueueName);
        System.out.println("send inventory status message... jsonString:" + jsonString + " inventoryTopic:" + inventoryTopic);
        TextMessage objmsg = session.createTextMessage();
        TopicPublisher publisher = session.createPublisher(inventoryTopic);
        objmsg.setIntProperty("Id", 1);
        objmsg.setIntProperty("Priority", 2);
        objmsg.setText(jsonString);
        objmsg.setJMSCorrelationID("" + 2);
        objmsg.setJMSPriority(2);
        publisher.publish(inventoryTopic, objmsg, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
     */
        System.out.println("sendInsertAndSendOrderMessage.........");
        String topicName = "sample.topic";
        Properties props = new Properties();
        props.put("bootstrap.servers", "kafka-service:9092");
        props.put("acks", "all");
        props.put("retries", 0);
        props.put("batch.size", 16384);
        props.put("linger.ms", 1);
        props.put("buffer.memory", 33554432);
        props.put("key.serializer",
                "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer",
                "org.apache.kafka.common.serialization.StringSerializer");
        Producer<String, String> producer = new KafkaProducer
                <String, String>(props);
        for(int i = 0; i < 1; i++) {
            producer.send(new ProducerRecord<String, String>(topicName,
                    Integer.toString(i), Integer.toString(i)));
            System.out.println(i +":Message sent successfully");
        }
        producer.close();
        System.out.println("Finished message send ");
    }

    private String evaluateInventory(String id) throws SQLException {
        String url = "jdbc:postgresql://postgres.msdataworkshop:5432/postgresdb";
        String user = "postgresadmin";
        String password = "admin123";
        try (
                Connection con = DriverManager.getConnection(url, user, password);
                Statement st = con.createStatement();
                ResultSet rs = st.executeQuery("SELECT VERSION()")) {
            if (rs.next()) {
                System.out.println("KafkaPostgresOrderEventConsumer  testConnection() con:" + con);
                System.out.println(rs.getString(1));
            }
        System.out.println("-------------->evaluateInventory for inventoryid:" + id);
//        try (OraclePreparedStatement st = (OraclePreparedStatement) dbConnection.prepareStatement(DECREMENT_BY_ID)) {
//            st.setString(1, id);
//            st.registerReturnParameter(2, Types.VARCHAR);
//            int i = st.executeUpdate();
//            ResultSet res = st.getReturnResultSet();
//            if (i > 0 && res.next()) {
//                String location = res.getString(1);
//                System.out.println("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} location {" + location + "}");
//                return location;
//            } else {
//                System.out.println("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} inventorydoesnotexist");
//                return "inventorydoesnotexist";
//            }
//        }

        } catch (
                SQLException ex) {
            ex.printStackTrace();
        }
        return "in philly";
    }



}
