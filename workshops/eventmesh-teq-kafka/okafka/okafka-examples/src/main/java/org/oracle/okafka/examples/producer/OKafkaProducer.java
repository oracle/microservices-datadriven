package org.oracle.okafka.examples.producer;

import org.apache.avro.Schema;

import org.oracle.okafka.clients.producer.KafkaProducer;
import org.oracle.okafka.clients.producer.ProducerRecord;
import org.oracle.okafka.common.config.SslConfigs;
import org.oracle.okafka.examples.model.DataRecord;

import java.util.Properties;

public class OKafkaProducer {

    public static void main(String[] args) {

        System.setProperty("org.slf4j.simpleLogger.defaultLogLevel", "DEBUG");

        String topic = "TEQ_SUCCESSFUL" ;

        KafkaProducer<String,String> prod = null;
        Properties props = new Properties();

        props.put("oracle.user.name","LAB8022_USER");
        props.put("oracle.password","Welcome#1@Oracle");

        // (description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)
        // (port=1522)(host=adb.us-ashburn-1.oraclecloud.com))
        // (connect_data=(service_name=bsenjiat5lmurtq_atpokafkalab_tp.adb.oraclecloud.com))
        // (security=(ssl_server_cert_dn="CN=adwc.uscom-east-1.oraclecloud.com, OU=Oracle BMCS US, O=Oracle Corporation, L=Redwood City, ST=California, C=US")))

        props.put("oracle.instance.name", "lab8022atp_tp"); //name of the oracle databse instance

        props.put("oracle.service.name", "bsenjiat5lmurtq_lab8022atp_tp.adb.oraclecloud.com");	//name of the service running on the instance


        // /Users/pasimoes/Work/Oracle/Labs/Grabdish/ATP/Wallet_psgrabdishi
        props.put("oracle.net.tns_admin", "/Users/pasimoes/Oracle/Code/Security/Wallets/lab8022atp"); //eg: "/msdataworkshop/creds" if ojdbc.properies file is in home
        //SSL
        props.put("security.protocol", "SSL");
        props.put(SslConfigs.TNS_ALIAS, "lab8022atp_tp");

        props.put("bootstrap.servers", "adb.us-ashburn-1.oraclecloud.com:1522"); //ip address or host name where instance running : port where instance listener running
        props.put("linger.ms", 1000);
        //props.put("batch.size", 200);
        //props.put("linger.ms", 100);
        //props.put("buffer.memory", 335544);
        props.put("key.serializer", "org.oracle.okafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.oracle.okafka.common.serialization.StringSerializer");

        System.out.println("Creating producer now 1 2 3..");

        prod=new KafkaProducer<String, String>(props);

        System.out.println("Producer created.");


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
        try {
            // Produce sample data
            final Long numMessages = 10L;
            for (Long i = 0L; i < numMessages; i++) {
                String key = "alice";
                DataRecord record = new DataRecord(i);

                System.out.printf("Producing record: %s\t%s%n", key, record);

                ProducerRecord prodRec = new ProducerRecord<String, String>(topic, 0, i + "000", record.toString());

                prod.send(prodRec);

                /*
                GenericRecord avroRecord = new GenericData.Record(schema);
                avroRecord.put("orderid", "order" + i);
                avroRecord.put("itemid", "item" + i);
                avroRecord.put("deliveryLocation", "Street " + i);
                avroRecord.put("status", "status");
                avroRecord.put("inventoryLocation", "Store" + i);
                avroRecord.put("suggestiveSale", "sale");

                System.out.println("Created Avro Record"+ avroRecord);

                String key = "key" + i;
                //ProducerRecord<String, String> record = new ProducerRecord(topic, 0, key, avroRecord.toString());
                String Msg = "Message " + i;
                //ProducerRecord<String, String> record = new ProducerRecord(topic, 0, key, Msg);
                ProducerRecord<String, String> record = new ProducerRecord(topic, key, Msg);

                System.out.println("Created ProdRec: " + record);

                producer.send(record);
                System.out.println("Sent message: " + i);

                 */
            }

            System.out.println("Sent "+ numMessages + " messages.");
        } catch(Exception ex) {
            System.out.println("Failed to send messages:");
            ex.printStackTrace();
        }
        finally {
            //producer.flush();
            prod.close();
        }

    }

}
