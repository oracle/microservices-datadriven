// Copyright (c) 2022, 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

// This is an example of how to consume a message from a TEQ using Java.
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
import oracle.jakarta.jms.AQjmsFactory;
import oracle.jakarta.jms.AQjmsSession;
import oracle.jakarta.jms.AQjmsTextMessage;
import oracle.jakarta.jms.AQjmsTopicSubscriber;
import oracle.jdbc.pool.OracleDataSource;

public class ConsumeTxEventQ {

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

        // create a subscriber on the topic
        Topic topic = session.getTopic(username, topicName);
        AQjmsTopicSubscriber subscriber = 
           (AQjmsTopicSubscriber) session.createDurableSubscriber(topic, "my_subscriber");

        System.out.println("Waiting for messages...");

        // wait forever for messages to arrive and print them out
        while (true) {

            // the 1_000 is a one second timeout
            AQjmsTextMessage message = (AQjmsTextMessage) subscriber.receive(1_000); 
            if (message != null) {
                if (message.getText() != null) {
                    System.out.println(message.getText());
                } else {
                    System.out.println();
                }
            }
            session.commit();
        }
    }

}