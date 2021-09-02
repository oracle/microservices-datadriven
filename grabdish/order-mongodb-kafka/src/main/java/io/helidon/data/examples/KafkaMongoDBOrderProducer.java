package io.helidon.data.examples;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.Future;

import com.mongodb.MongoClient;
import com.mongodb.client.FindIterable;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.model.Filters;
import org.apache.kafka.clients.consumer.ConsumerGroupMetadata;
import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.Metric;
import org.apache.kafka.common.MetricName;
import org.apache.kafka.common.PartitionInfo;
import org.apache.kafka.common.errors.ProducerFencedException;
import org.apache.kafka.common.serialization.Serializer;
import org.bson.Document;

import static io.helidon.data.examples.KafkaMongoOrderResource.crashAfterInsert;

public class KafkaMongoDBOrderProducer {

    public String updateDataAndSendEvent(String orderid, String itemid, String deliverylocation) {
        System.out.println("KafkaMongoDBOrderProducer.updateDataAndSendEvent orderid = " + orderid + ", itemid = " + itemid + ", deliverylocation = " + deliverylocation);
        System.out.println("KafkaMongoDBOrderProducer.insert order into mongodb.........");
        Order insertedOrder = insertOrderInMongoDB(orderid, itemid, deliverylocation);
        if (crashAfterInsert) System.exit(-1);
        String jsonString = JsonUtils.writeValueAsString(insertedOrder);
        System.out.println("send message to kafka.........");
        String topicName = KafkaMongoOrderResource.orderTopicName;
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
                    "order", jsonString));
        System.out.println("KafkaMongoDBOrderProducer.Message sent successfully:" + jsonString);
        producer.close();
        return "end send messages";
    }

    public Order insertOrderInMongoDB(String orderid, String itemid, String deliverylocation) {
        System.out.println("insertOrderInMongoDB orderid = " + orderid + ", itemid = " + itemid + ", deliverylocation = " + deliverylocation);
        Order order = new Order(orderid, itemid, deliverylocation, "pending", "", "");
        MongoClient mongoClient = KafkaMongoOrderEventConsumer.getMongoClient();
        MongoCollection<Document> orders = KafkaMongoOrderEventConsumer.getDocumentMongoCollection(mongoClient);
        orders.insertOne(new Document()
                .append("orderid", orderid)
                .append("itemid", itemid)
                .append("deliverylocation", deliverylocation)
                .append("status", "pending")
        );
        mongoClient.close();
        return order;
}


    public Order getOrderFromMongoDB(String orderId) {
        System.out.println("KafkaMongoDBOrderProducer.getOrderFromMongoDB orderId:" + orderId);
        MongoClient mongoClient = KafkaMongoOrderEventConsumer.getMongoClient();
        MongoCollection<Document> orders = KafkaMongoOrderEventConsumer.getDocumentMongoCollection(mongoClient);
        FindIterable<Document> documentFindIterable = orders.find(Filters.eq("orderid", orderId));
        if (documentFindIterable == null) {
            System.out.println("KafkaMongoDBOrderProducer.getOrderFromMongoDB no entry found for orderId:" + orderId);
        }
        for(Document doc : documentFindIterable) {
            String inventorylocation = doc.getString("inventorylocation");
            System.out.println("KafkaMongoDBOrderProducer.getOrderFromMongoDB inventorylocation:" + inventorylocation);
            return new Order(orderId, doc.getString("itemid"), doc.getString("deliverylocation"), doc.getString("status"), inventorylocation, doc.getString("suggestiveSale"));
        }
        return new Order(orderId, "unknown", "unknown", "unknown", "", "");
    }

    public String deleteOrderFromMongoDB(String orderId) {
        MongoClient mongoClient = KafkaMongoOrderEventConsumer.getMongoClient();
        MongoCollection<Document> orders = KafkaMongoOrderEventConsumer.getDocumentMongoCollection(mongoClient);
        orders.deleteOne(Filters.eq("orderid", orderId));
        return "orderId:" + orderId + " deleted";
    }

    public Object dropOrderFromMongoDB() {
        MongoClient mongoClient = KafkaMongoOrderEventConsumer.getMongoClient();
        MongoCollection<Document> orders = KafkaMongoOrderEventConsumer.getDocumentMongoCollection(mongoClient);
        orders.drop();
        return "orders collection dropped";
    }

}