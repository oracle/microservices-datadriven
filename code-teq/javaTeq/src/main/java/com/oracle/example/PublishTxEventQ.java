// Copyright (c) 2022, 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

// This is an example of how to publish a message onto a TEQ using Java.
// Please see the Maven POM file for dependencies.

package com.oracle.example;

import java.sql.Connection;
import java.sql.SQLException;

import jakarta.jms.JMSException;
import jakarta.jms.Session;
import jakarta.jms.Topic;
import jakarta.jms.TopicConnection;
import jakarta.jms.TopicConnectionFactory;

import oracle.AQ.AQException;
import oracle.jakarta.jms.AQjmsAgent;
import oracle.jakarta.jms.AQjmsFactory;
import oracle.jakarta.jms.AQjmsSession;
import oracle.jakarta.jms.AQjmsTextMessage;
import oracle.jakarta.jms.AQjmsTopicPublisher;
import oracle.jdbc.pool.OracleDataSource;

public class PublishTxEventQ {

    private static final String username = "testuser";
    private static final String url = "jdbc:oracle:thin:@//localhost:1521/freepdb1";
    private static final String password = "Welcome12345";
    private static final String topicName = "my_jms_teq";

    public static void main(String[] args) throws AQException, SQLException, JMSException {

        // Create DB connection
        OracleDataSource ds = new OracleDataSource();
        ds.setURL(url);
        ds.setUser(username);
        ds.setPassword(password);
        Connection con = ds.getConnection();
        if (con != null) {
            System.out.println("Connected!");
        }

        // create a JMS topic connection and session
        TopicConnectionFactory tcf = AQjmsFactory.getTopicConnectionFactory(ds);
        TopicConnection conn = tcf.createTopicConnection();
        conn.start();
        var session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);

        // publish message
        Topic topic = session.getTopic(username, topicName);
        AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);

        AQjmsTextMessage message = (AQjmsTextMessage) session.createTextMessage("hello from java");
        publisher.publish(message, new AQjmsAgent[] { new AQjmsAgent("my_subscription", null) });
        session.commit();

        // clean up
        publisher.close();
        session.close();
        conn.close();
    }

}