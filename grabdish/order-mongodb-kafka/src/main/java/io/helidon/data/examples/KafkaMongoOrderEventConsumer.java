package io.helidon.data.examples;


import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.util.Arrays;
import java.util.Properties;

public class KafkaMongoOrderEventConsumer implements Runnable {

    @Override
    public void run() {
        System.out.println("Receive messages...");
//        try {
        dolistenForMessages();
//        } catch (JMSException e) {
//            e.printStackTrace();
//        }
    }

    public void dolistenForMessages() {
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
                        record.offset(), record.key(), record.value());

//                TextMessage orderMessage = (TextMessage) (consumer.receive(-1));  //todo address JMS-257: receive(long timeout) of javax.jms.MessageConsumer took more time than the network timeout configured at the java.sql.Connection.
//                String txt = orderMessage.getText();
//                System.out.println("txt " + txt);
//                System.out.print("JMSPriority: " + orderMessage.getJMSPriority());
//                System.out.println("Priority: " + orderMessage.getIntProperty("Priority"));
//                System.out.print(" Message: " + orderMessage.getIntProperty("Id"));
//                Order order = JsonUtils.read(txt, Order.class);
//                System.out.print(" orderid:" + order.getOrderid());
//                System.out.print(" itemid:" + order.getItemid());

                //          updateDataAndSendEventOnInventory((AQjmsSession) qsess, order.getOrderid(), order.getItemid());
                String messageText = record.value();
                Inventory inventory = JsonUtils.read(messageText, Inventory.class);
                String orderid = inventory.getOrderid();
                String itemid = inventory.getItemid();
                String inventorylocation = inventory.getInventorylocation();
                System.out.println("Lookup orderid:" + orderid + "(itemid:" + itemid + ")");
                Order order = null; //get order json from kafka message
                boolean isSuccessfulInventoryCheck = !(inventorylocation == null || inventorylocation.equals("")
                        || inventorylocation.equals("inventorydoesnotexist")
                        || inventorylocation.equals("none"));
                if (isSuccessfulInventoryCheck) {
                    order.setStatus("success inventory exists");
                    order.setInventoryLocation(inventorylocation);
                    order.setSuggestiveSale(inventory.getSuggestiveSale());
                } else {
                    order.setStatus("failed inventory does not exist");
                }
            }
        }
    }
}
