/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package com.helidon.se.persistence.context;

import java.sql.SQLException;
import java.util.Objects;
import java.util.function.BiFunction;

import javax.jms.*;

import oracle.jms.AQjmsConstants;
import org.slf4j.Logger;

import com.helidon.se.persistence.Database;
import com.helidon.se.util.JsonUtils;

import oracle.jdbc.OracleConnection;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.*;

public class OracleJmsDBContext extends DBContext {

    private final TopicConnectionFactory factory;
    private TopicConnection jmsConnection;
    private TopicSession session;
    private OracleConnection oracleConnection;

    public OracleJmsDBContext(Database db, BiFunction<Throwable, Integer, Long> retryFunction, Logger log)
            throws JMSException {
        super(db, retryFunction, log);
        this.factory = AQjmsFactory.getTopicConnectionFactory(db.getDataSource());

    }

    private boolean hasActiveConnection() throws SQLException {
        return Objects.nonNull(session) && Objects.nonNull(jmsConnection) && Objects.nonNull(oracleConnection)
                && !oracleConnection.isClosed();
    }

    @Override
    public OracleConnection getConnection() throws JMSException, SQLException {
        if (!hasActiveConnection()) {
            this.jmsConnection = factory.createTopicConnection();
            this.jmsConnection.start();
            this.session = jmsConnection.createTopicSession(true, 0);
            this.oracleConnection = (OracleConnection) ((AQjmsSession) session).getDBConnection();
        }
        return oracleConnection;
    }

    @Override
    public void close() throws SQLException, JMSException {
        if (Objects.nonNull(jmsConnection)) {
            try {
                jmsConnection.stop();
                jmsConnection.close();
                this.jmsConnection = null;
            } catch (JMSException e) {
                this.jmsConnection = null;
            }
        }
        if (Objects.nonNull(session)) {
            session.close();
            this.jmsConnection = null;
        }
        if (Objects.nonNull(oracleConnection)) {
            if (!oracleConnection.isClosed()) {
                oracleConnection.close();
            }
            this.oracleConnection = null;
        }
    }

    @Override
    public String sendMessage(Object message, String owner, String queueName) throws JMSException, SQLException {
        getConnection(); // using for init connections if needed
        // using a topic, but not a queue because queues are multiple_consumers   => true in DB
        Topic topic = ((AQjmsSession) session).getTopic(owner, queueName);
        TopicPublisher publisher = session.createPublisher(topic);
        TextMessage jmsMessage = session.createTextMessage(JsonUtils.writeValueAsString(message));
        jmsMessage.setIntProperty("Id", 1);
        jmsMessage.setIntProperty("Priority", 2);
//        jmsMessage.setJMSCorrelationID("" + 2);
        jmsMessage.setJMSPriority(2);
        publisher.publish(topic, jmsMessage, DeliveryMode.PERSISTENT,2, AQjmsConstants.EXPIRATION_NEVER);
        session.commit();
        String id = jmsMessage.getJMSMessageID();
        log.debug("Sent to {} message {}, id {}", queueName, message, id);
        return id;
    }

    @Override
    public String getMessage(String owner, String queueName) throws JMSException, SQLException {
        getConnection(); // using for init connections if needed
        Topic orderEvents = ((AQjmsSession) session).getTopic(owner, queueName);
        TopicReceiver receiver = ((AQjmsSession) session).createTopicReceiver(orderEvents, "inventory_service", null);
        TextMessage message = (TextMessage) receiver.receive(-1);
//        MessageConsumer consumer = session.createConsumer(queue);
//        TextMessage message = (TextMessage) consumer.receive(-1);
        if (message != null) {
            String id = message.getJMSMessageID();
            String body = message.getText();
            log.debug("Received from {} message {}, id {}", queueName, body, id);
            return body;
        } else {
            return null;
        }
    }
}
