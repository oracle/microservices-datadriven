package com.oracle.demo.lab.events;

import java.sql.*;

import com.oracle.demo.lab.ticket.SupportTicket;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.oracle.okafka.clients.producer.KafkaProducer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("events")
public class TicketEventProducer {
    private static final Logger log = LoggerFactory.getLogger(TicketEventProducer.class);

    private final KafkaProducer<String, SupportTicket> producer;
    private final String topic;

    public TicketEventProducer(KafkaProducer<String, SupportTicket> producer,
                               @Value("${okafka.topic.tickets}") String topic) {
        this.producer = producer;
        this.topic = topic;
    }

    public Long produce(SupportTicket ticket) {
        final String insertTicket = """
                insert into support_ticket
                (title, description)
                values (?, ?)
                """;

        producer.beginTransaction();
        Connection conn = producer.getDBConnection();
        try (PreparedStatement ps = conn.prepareStatement(insertTicket, new String[]{"id",})) {
            ps.setString(1, ticket.getTitle());
            ps.setString(2, ticket.getDescription());
            ps.executeUpdate();

            try (ResultSet generatedKeys = ps.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    ticket.setId(generatedKeys.getLong(1));
                } else {
                    throw new SQLException("Creating user failed, no ID obtained.");
                }
            }
            ProducerRecord<String, SupportTicket> record = ticket.toProducerRecord(topic);
            // Send the event to oracle database
            producer.send(record);
            // Commit the transaction
            producer.commitTransaction();
            log.info("Created new ticket id: {}", ticket.getId());
            return ticket.getId();
        } catch (SQLException e) {
            producer.abortTransaction();
            throw new RuntimeException(e);
        }
    }
}
