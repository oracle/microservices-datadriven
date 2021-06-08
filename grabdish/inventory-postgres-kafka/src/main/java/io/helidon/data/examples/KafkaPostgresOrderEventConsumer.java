/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.sql.*;


import java.util.Properties;
import java.util.Arrays;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

public class KafkaPostgresOrderEventConsumer implements Runnable {


    final static String orderTopicName = "order.topic";
    final static String inventoryTopicName = "inventory.topic";
    KafkaPostgressInventoryResource inventoryResource;

    public KafkaPostgresOrderEventConsumer(KafkaPostgressInventoryResource inventoryResource) throws SQLException {
        this.inventoryResource = inventoryResource;
        setupDB(inventoryResource.postgresDataSource.getConnection());
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

    public void listenForOrderEvents()  {
        String topicName = orderTopicName;
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
        System.out.println("KafkaPostgresOrderEventConsumer  about to listen for messages...");
        KafkaConsumer<String, String> consumer = new KafkaConsumer  <String, String>(props);
        System.out.println("KafkaPostgresOrderEventConsumer  consumer:" + consumer);
        consumer.subscribe(Arrays.asList(topicName));
        System.out.println("Subscribed to topic " + topicName);
        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(100);
            for (ConsumerRecord<String, String> record : records) {
                System.out.printf("KafkaPostgresOrderEventConsumer message offset = %d, key = %s, value = %s\n",
                        record.offset(), record.key(), record.value());
                String txt = record.value();
                System.out.println("KafkaPostgresOrderEventConsumer txt " + txt);
                if (txt.indexOf("{") > -1) try {
                    Order order = JsonUtils.read(txt, Order.class);
                    System.out.print(" orderid:" + order.getOrderid());
                    System.out.print(" itemid:" + order.getItemid());
                    updateDataAndSendEventOnInventory(order.getOrderid(), order.getItemid());
                } catch (Exception ex) {
                    System.out.printf("message did not contain order");
                    ex.printStackTrace();
                }
            }
        }
    }

    private void updateDataAndSendEventOnInventory( String orderid, String itemid) throws Exception {
        if (inventoryResource.crashAfterOrderMessageReceived) System.exit(-1);
        String inventorylocation = evaluateInventory(itemid);
        Inventory inventory = new Inventory(orderid, itemid, inventorylocation, "beer"); //static suggestiveSale - represents an additional service/event
        String jsonString = JsonUtils.writeValueAsString(inventory);
        System.out.println("send inventory status message... jsonString:" + jsonString );
        if (inventoryResource.crashAfterOrderMessageProcessed) System.exit(-1);
        String topicName = inventoryTopicName;
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
            producer.send(new ProducerRecord<String, String>(topicName,
                    "inventory", jsonString));
        System.out.println("KafkaPostgresOrderEventConsumer.Message sent successfully:" + jsonString);
        producer.close();
    }

    private String evaluateInventory(String id) {
        System.out.println("KafkaPostgresOrderEventConsumer postgresDataSource:" + inventoryResource.postgresDataSource);
        System.out.println("KafkaPostgresOrderEventConsumer evaluateInventory for inventoryid:" + id);
        try (PreparedStatement st =   inventoryResource.postgresDataSource.getConnection().prepareStatement(
                "select inventorycount, inventorylocation from inventory where inventoryid = ?"
        )) {
            st.setString(1, id);
            ResultSet rs = st.executeQuery();
            rs.next();
            int inventoryCount = rs.getInt(1);
            String inventorylocation = rs.getString(2);
            rs.close();
            System.out.println("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} location {" + inventorylocation + "} inventoryCount:" + inventoryCount);
            if (inventoryCount > 0) {
                PreparedStatement decrementPS = inventoryResource.postgresDataSource.getConnection().prepareStatement(
                        "update inventory set inventorycount = ? where inventoryid = ?");
                decrementPS.setInt(1, inventoryCount - 1);
                decrementPS.setString(2, id);
                decrementPS.execute();
                System.out.println("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory reduced inventory count to:" + (inventoryCount - 1));
                return inventorylocation;
            } else {
                return "inventorydoesnotexist";
            }
        } catch (SQLException throwables) {
            throwables.printStackTrace();
        }
        return "unable to find inventory status";
    }

    private void setupDB(Connection connection) throws SQLException {
        createInventoryTable(connection);
        populateInventoryTable(connection);
    }

    private void createInventoryTable(Connection connection) throws SQLException {
        System.out.println("KafkaPostgresOrderEventConsumer createInventoryTable IF NOT EXISTS");
        connection.prepareStatement(
        "CREATE TABLE IF NOT EXISTS inventory ( inventoryid varchar(16) PRIMARY KEY NOT NULL, inventorylocation varchar(32), inventorycount integer CONSTRAINT positive_inventory CHECK (inventorycount >= 0) )").execute();
    }

    private void populateInventoryTable(Connection connection) throws SQLException {
        System.out.println("KafkaPostgresOrderEventConsumer populateInventoryTable if not populated");
        connection.prepareStatement("insert into inventory values ('sushi', '1468 WEBSTER ST,San Francisco,CA', 0) ON CONFLICT DO NOTHING").execute();
        connection.prepareStatement("insert into inventory values ('pizza', '1469 WEBSTER ST,San Francisco,CA', 0) ON CONFLICT DO NOTHING").execute();
        connection.prepareStatement("insert into inventory values ('burger', '1470 WEBSTER ST,San Francisco,CA', 0) ON CONFLICT DO NOTHING").execute();
    }


}
