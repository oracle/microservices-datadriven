// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

// This is an example of how to consume a message from a TEQ using Java.
// Please see the Maven POM file for dependencies.

package com.oracle.example;

import java.sql.SQLException;

import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.Topic;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;
import javax.jms.TopicSession;

import oracle.AQ.AQException;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;
import oracle.jms.AQjmsTopicSubscriber;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class ConsumeTEQ {

    private static String username = "pdbadmin";
    private static String url = "jdbc:oracle:thin:@//localhost:1521/pdb1";
    private static String topicName = "my_teq";

    public static void main(String[] args) throws AQException, SQLException, JMSException {

        // create a topic session
        PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
        ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        ds.setURL(url);
        ds.setUser(username);
        ds.setPassword(System.getenv("DB_PASSWORD"));

        // create a JMS topic connection and session
        TopicConnectionFactory tcf = AQjmsFactory.getTopicConnectionFactory(ds);
        TopicConnection conn = tcf.createTopicConnection();
        conn.start();
        TopicSession session = 
           (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);

        // create a subscriber on the topic
        Topic topic = ((AQjmsSession) session).getTopic(username, topicName);
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