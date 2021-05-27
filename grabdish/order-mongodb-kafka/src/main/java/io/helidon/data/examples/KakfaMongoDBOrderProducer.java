package io.helidon.data.examples;

import java.sql.Connection;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.bson.Document;

import javax.sql.DataSource;

public class KakfaMongoDBOrderProducer {

    public String updateDataAndSendEvent(String orderid, String itemid, String deliverylocation) throws Exception{
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
        for(int i = 0; i < 10; i++) {
            producer.send(new ProducerRecord<String, String>(topicName,
                    Integer.toString(i), Integer.toString(i)));
            System.out.println(i +":Message sent successfully");
        }
        producer.close();
        System.out.println("Finished message send - now testMongodbConnection()");
        testMongodbConnection();
        return "end send messages";
    }

    public void testMongodbConnection() {
            List<Document> seedData = new ArrayList<Document>();
            seedData.add(new Document("decade", "1970s")
                    .append("artist", "Debby Boone")
                    .append("song", "You Light Up My Life")
                    .append("weeksAtOne", 10)
            );

            seedData.add(new Document("decade", "1980s")
                    .append("artist", "Olivia Newton-John")
                    .append("song", "Physical")
                    .append("weeksAtOne", 10)
            );

            seedData.add(new Document("decade", "1990s")
                    .append("artist", "Mariah Carey")
                    .append("song", "One Sweet Day")
                    .append("weeksAtOne", 16)
            );

            // Standard URI format: mongodb://[dbuser:dbpassword@]host:port/dbname
//            MongoClientURI uri  = new MongoClientURI("mongodb://orderuser:Welcome12345@mongodb:27017/orderdb");
            MongoClientURI uri  = new MongoClientURI("mongodb://mongodb:27017");
            MongoClient client = new MongoClient(uri);
            MongoDatabase db = client.getDatabase(uri.getDatabase());
        System.out.println("testMongodbConnection() db:" + db);
            MongoCollection<Document> songs = db.getCollection("songs");
        System.out.println("testMongodbConnection() insert..:" + db);
            songs.insertMany(seedData);
        System.out.println("testMongodbConnection() done insert:" + db);
            Document updateQuery = new Document("song", "One Sweet Day");
            songs.updateOne(updateQuery, new Document("$set", new Document("artist", "Mariah Carey ft. Boyz II Men")));
            Document findQuery = new Document("weeksAtOne", new Document("$gte",10));
            Document orderBy = new Document("decade", 1);
            MongoCursor<Document> cursor = songs.find(findQuery).sort(orderBy).iterator();
            try {
                while (cursor.hasNext()) {
                    Document doc = cursor.next();
                    System.out.println(
                            "In the " + doc.get("decade") + ", " + doc.get("song") +
                                    " by " + doc.get("artist") + " topped the charts for " +
                                    doc.get("weeksAtOne") + " straight weeks."
                    );
                }
            } finally {
                cursor.close();
            }
            songs.drop();
            client.close();
    }



    public Order getOrderViaSODA(String orderId) {
        return null;
    }

    public String deleteOrderViaSODA(String orderId) {
        return null;
    }

    public Object dropOrderViaSODA() {
        return null;
    }
}