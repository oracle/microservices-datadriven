package com.oracle.demo.lab.events;

import java.time.Duration;
import java.util.Collections;

import com.oracle.demo.lab.ticket.SupportTicket;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.oracle.okafka.clients.consumer.KafkaConsumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("events")
public class TicketEventConsumer implements Runnable {
    private static final Logger log = LoggerFactory.getLogger(TicketEventConsumer.class);
    private final KafkaConsumer<String, SupportTicket> consumer;
    private final TicketEventProcessor eventProcessor;
    private final String topic;

    public TicketEventConsumer(KafkaConsumer<String, SupportTicket> consumer,
                               TicketEventProcessor eventProcessor,
                               @Value("${okafka.topic.tickets}") String topic) {
        this.consumer = consumer;
        this.eventProcessor = eventProcessor;
        this.topic = topic;
    }

    public void run() {
        consumer.subscribe(Collections.singletonList(topic));
        log.info("Subscribed to topic {}", topic);
        while (true) {
            try {
                ConsumerRecords<String, SupportTicket> records = consumer.poll(Duration.ofMillis(2000));
                for (ConsumerRecord<String, SupportTicket> record : records) {
                    // You may choose to do asynchronous processing here,
                    // as each event may take some time (embed -> vector search -> database update)
                    eventProcessor.processRecord(consumer.getDBConnection(), record.value());
                }
                consumer.commitSync();
                if (records.count() > 0) {
                    log.info("Committed {} record(s)", records.count());
                }
            } catch (Exception e) {
                log.error("Error consuming records", e);
            }

        }
    }

}
