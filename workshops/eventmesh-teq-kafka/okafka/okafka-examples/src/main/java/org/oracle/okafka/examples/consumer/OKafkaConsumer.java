package org.oracle.okafka.examples.consumer;

import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericRecord;
import org.oracle.okafka.clients.consumer.Consumer;
import org.oracle.okafka.clients.consumer.ConsumerRecord;
import org.oracle.okafka.clients.consumer.ConsumerRecords;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import org.oracle.okafka.common.config.SslConfigs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;

public class OKafkaConsumer {

    private static final Logger logger = LoggerFactory.getLogger(OKafkaConsumer.class);

    public static void main(String[] args) {

        logger.debug("Testing 123");

        Properties props = new Properties();

        String topic = "TEQ_SUCCESSFUL" ;

        props.put("oracle.user.name","LAB8022_USER");
        props.put("oracle.password","Welcome#1@Oracle");

        props.put("oracle.instance.name", "lab8022atp_tp"); //name of the oracle databse instance

        // bsenjiat5lmurtq_psgrabdishi_tp.adb.oraclecloud.com
        props.put("oracle.service.name", "bsenjiat5lmurtq_lab8022atp_tp.adb.oraclecloud.com");	//name of the service running on the instance

        // /Users/pasimoes/Work/Oracle/Labs/Grabdish/ATP/Wallet_psgrabdishi
        props.put("oracle.net.tns_admin", "/Users/pasimoes/Oracle/Code/Security/Wallets/lab8022atp");

        props.put("security.protocol", "SSL");
        props.put(SslConfigs.TNS_ALIAS, "lab8022atp_tp");

        props.put("bootstrap.servers", "adb.us-ashburn-1.oraclecloud.com:1522"); //ip address or host name where instance running : port where instance listener running
        props.put("group.id", "successfulSubscriber");
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
            ConsumerRecords<String, GenericRecord> records = consumer.poll(Duration.ofMillis(25000));
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
