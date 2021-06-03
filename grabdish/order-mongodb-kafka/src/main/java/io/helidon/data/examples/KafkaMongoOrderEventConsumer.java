package io.helidon.data.examples;


import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.bson.Document;

import javax.inject.Inject;
import javax.inject.Named;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;

public class KafkaMongoOrderEventConsumer implements Runnable {


    Properties props = new Properties();
    static MongoClientURI uri = new MongoClientURI("mongodb://orderuser:Welcome12345@mongodb:27017/orderdb");

    static MongoClient getMongoClient() {
        return new MongoClient(KafkaMongoOrderEventConsumer.uri);
    }

    static MongoCollection<Document> getDocumentMongoCollection(MongoClient mongoClient) {
        MongoDatabase db = mongoClient.getDatabase(KafkaMongoOrderEventConsumer.uri.getDatabase());
        return db.getCollection("orders");
    }

    @Override
    public void run() {
        // Standard URI format: mongodb://[dbuser:dbpassword@]host:port/dbname
//            MongoClientURI uri  = new MongoClientURI("mongodb://mongodb:27017");
        uri = new MongoClientURI("mongodb://orderuser:Welcome12345@mongodb:27017/orderdb");
        props.put("bootstrap.servers", "kafka-service:9092");
        props.put("group.id", "test");
        props.put("enable.auto.commit", "true");
        props.put("auto.commit.interval.ms", "1000");
        props.put("session.timeout.ms", "30000");
        props.put("key.deserializer",
                "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer",
                "org.apache.kafka.common.serialization.StringDeserializer");
        //todo potentially gate this for init
//        createTopic(KafkaMongoOrderResource.orderTopicName);
//        createTopic(KafkaMongoOrderResource.inventoryTopicName);
        dolistenForMessages();
    }

    private void createTopic(String topicName) {
        System.out.println("KafkaMongoOrderEventConsumer.createTopic creating " + topicName + "... ");
        AdminClient adminClient = AdminClient.create(props);
        NewTopic newTopic = new NewTopic(topicName, 1, (short) 1); //new NewTopic(topicName, numPartitions, replicationFactor)
        List<NewTopic> newTopics = new ArrayList<NewTopic>();
        newTopics.add(newTopic);
        adminClient.createTopics(newTopics);
        adminClient.close();
    }

    public void dolistenForMessages() {
        System.out.println("KafkaPostgresOrderEventConsumer  about to listen for messages...");
        KafkaConsumer<String, String> consumer = new KafkaConsumer
                <String, String>(props);
        System.out.println("KafkaPostgresOrderEventConsumer  consumer:" + consumer);
        consumer.subscribe(Arrays.asList(KafkaMongoOrderResource.inventoryTopicName));
        System.out.println("Subscribed to topic " + KafkaMongoOrderResource.inventoryTopicName);
        while (true) {
            ConsumerRecords<String, String> records = consumer.poll(100);
            for (ConsumerRecord<String, String> record : records) {
                System.out.printf("message offset = %d, key = %s, value = %s\n",
                        record.offset(), record.key(), record.value());
                String messageText = record.value();
                if (messageText.indexOf("{") > -1) {
                    Inventory inventory = JsonUtils.read(messageText, Inventory.class);
                    String orderid = inventory.getOrderid();
                    String itemid = inventory.getItemid();
                    String inventorylocation = inventory.getInventorylocation();
                    boolean isSuccessfulInventoryCheck = !(inventorylocation == null || inventorylocation.equals("")
                            || inventorylocation.equals("inventorydoesnotexist")
                            || inventorylocation.equals("none"));
                    System.out.println("Update orderid:" + orderid + "(itemid:" + itemid + ") in MongoDB isSuccessfulInventoryCheck:" + isSuccessfulInventoryCheck);
                    MongoClient mongoClient = getMongoClient();
                    MongoCollection<Document> orders = getDocumentMongoCollection(mongoClient);
                    Document updateQuery = new Document().append("orderid", orderid);
                    if (isSuccessfulInventoryCheck) {
                        orders.updateOne(updateQuery, new Document("$set", new Document("inventorylocation", inventorylocation)));
//                        order.setStatus("success inventory exists");
//                        order.setSuggestiveSale(inventory.getSuggestiveSale());
                    } else {
                        orders.updateOne(updateQuery, new Document("$set", new Document("inventorylocation", "failed inventory does not exist")));
                    }

                }
            }
        }
    }
}
