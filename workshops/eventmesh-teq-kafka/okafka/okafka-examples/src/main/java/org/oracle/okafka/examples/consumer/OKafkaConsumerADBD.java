package org.oracle.okafka.examples.consumer;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.oracle.okafka.clients.consumer.Consumer;
import org.oracle.okafka.clients.consumer.ConsumerRecord;
import org.oracle.okafka.clients.consumer.ConsumerRecords;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import org.oracle.okafka.common.config.SslConfigs;

import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;

public class OKafkaConsumerADBD {

    public static void main(String[] args) {

        System.setProperty("org.slf4j.simpleLogger.defaultLogLevel", "DEBUG");

        Properties props = new Properties();

        String topic = "LAB8022_TOPIC" ;

        props.put("oracle.user.name","LAB8022_USER");
        props.put("oracle.password","W3lcome@123456");

        props.put("oracle.instance.name", "db202110141444_medium"); //name of the oracle databse instance
        props.put("oracle.service.name", "DB202110141444_medium.atp.oraclecloud.com");	//name of the service running on the instance

        props.put("oracle.net.tns_admin", "/Users/pasimoes/Work/Oracle/Code/aq-teq/microservices-datadriven/workshops/eventmesh-teq-kafka/wallet/adb-d"); //eg: "/msdataworkshop/creds" if ojdbc.properies file is in home
        //SSL
        props.put("security.protocol", "SSL");
        props.put(SslConfigs.TNS_ALIAS, "db202110141444_medium");

        props.put("bootstrap.servers", "127.0.0.1:1521"); //ip address or host name where instance running : port where instance listener running
        props.put("group.id", "LAB8022_SUBSCRIBER");
        props.put("enable.auto.commit", "true");
        props.put("auto.commit.interval.ms", "10000");

        props.put("key.deserializer",
                "org.oracle.okafka.common.serialization.StringDeserializer");
        props.put("value.deserializer",
                "org.oracle.okafka.common.serialization.StringDeserializer");
        props.put("max.poll.records", 100);

        //KafkaConsumer<String, String> consumer = null;
        //consumer = new KafkaConsumer<String, String>(props);

        Consumer<String, GenericRecord> consumer = new KafkaConsumer<String, GenericRecord>(props);

        consumer.subscribe(Arrays.asList(topic));

        System.out.println("Consumer: " + consumer.toString());

        final String ORDER_EVT_SCHEMA =  "{\"type\":\"record\"," +
                "\"doc\":\"This event records the order\"," +
                "\"name\":\"OrderEvent\"," +
                "\"fields\":[{\"name\":\"orderid\",\"type\":\"string\"},"+
                "{\"name\":\"itemid\",\"type\":\"string\"},"+
                "{\"name\":\"deliveryLocation\",\"type\":\"string\"},"+
                "{\"name\":\"status\",\"type\":\"string\"},"+
                "{\"name\":\"inventoryLocation\",\"type\":\"string\"},"+
                "{\"name\":\"suggestiveSale\",\"type\":\"string\"}"+
                "]}";

        Schema.Parser parser = new Schema.Parser();
        Schema schema = parser.parse(ORDER_EVT_SCHEMA);

        GenericRecord avroRecord = new GenericData.Record(schema);

        try {
            // TODO There is a issue with elapsedTime usually greater timeoutMs
            //  (I tested with 10000 and gave timeout and didn't returning nothing)
            ConsumerRecords<String, GenericRecord> records = consumer.poll(Duration.ofMillis(120000));
            System.out.println("Records: " + records.count());

            for (ConsumerRecord<String, GenericRecord> record : records) {
                System.out.println("topic = , partition=  ,key= , value = \n"+
                        record.topic()+ "  "+record.partition()+ "  "+record.key()+"  "+ record.value());
                System.out.println(".......");
            }

            consumer.commitSync();

        }catch(Exception ex) {
            ex.printStackTrace();

        } finally {
            consumer.close();
        }

    }

}
