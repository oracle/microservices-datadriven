// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

// This is an example of how to create a TEQ using Java.
// Please see the Maven POM file for dependencies.

package com.oracle.example;

import java.sql.SQLException;

import jakarta.jms.Destination;
import jakarta.jms.JMSException;
import jakarta.jms.Session;
import jakarta.jms.TopicConnection;
import jakarta.jms.TopicConnectionFactory;

import oracle.AQ.AQException;
import oracle.AQ.AQQueueTableProperty;
import oracle.jakarta.jms.AQjmsDestination;
import oracle.jakarta.jms.AQjmsFactory;
import oracle.jakarta.jms.AQjmsSession;

import oracle.jdbc.pool.OracleDataSource;
import java.sql.Connection;

public class CreateTxEventQ {

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

        // create a topic session
        TopicConnectionFactory tcf = AQjmsFactory.getTopicConnectionFactory(ds);
        TopicConnection conn = tcf.createTopicConnection();
        conn.start();
        AQjmsSession session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);

        // create properties
        AQQueueTableProperty props = new AQQueueTableProperty("SYS.AQ$_JMS_TEXT_MESSAGE");
        props.setMultiConsumer(true);
        props.setPayloadType("SYS.AQ$_JMS_TEXT_MESSAGE");

        // create queue table, topic and start it
        Destination myTeq = session.createJMSTransactionalEventQueue(topicName, true);
        ((AQjmsDestination) myTeq).start(session, true, true);

        if (con != null && !con.isClosed()) {
            con.close();
        }
    }

}