// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

// This is an example of how to create a TEQ using Java.
// Please see the Maven POM file for dependencies.

package com.oracle.example;

import java.sql.SQLException;

import javax.jms.Destination;
import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;
import javax.jms.TopicSession;

import oracle.AQ.AQException;
import oracle.AQ.AQQueueTableProperty;
import oracle.jms.AQjmsDestination;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class CreateTEQ {

    private static String username = "pdbadmin";
    private static String url = "jdbc:oracle:thin:@//localhost:1521/pdb1";

    public static void main(String[] args) throws AQException, SQLException, JMSException {
        
        // create a topic session
        PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
        ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        ds.setURL(url);
        ds.setUser(username);
        ds.setPassword(System.getenv("DB_PASSWORD"));

        TopicConnectionFactory tcf = AQjmsFactory.getTopicConnectionFactory(ds);
        TopicConnection conn = tcf.createTopicConnection();
        conn.start();
        TopicSession session = (AQjmsSession) conn.createSession(true, Session.AUTO_ACKNOWLEDGE);

        // create properties
        AQQueueTableProperty props = new AQQueueTableProperty("SYS.AQ$_JMS_TEXT_MESAGE");
        props.setMultiConsumer(true);
        props.setPayloadType("SYS.AQ$_JMS_TEXT_MESSAGE");

        // create queue table, topic and start it
        Destination myTeq = ((AQjmsSession) session).createJMSTransactionalEventQueue("my_jms_teq", true);
        ((AQjmsDestination) myTeq).start(session, true, true);

    }

}