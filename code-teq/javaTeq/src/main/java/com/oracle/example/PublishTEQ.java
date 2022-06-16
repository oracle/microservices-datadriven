package com.oracle.example;

import java.sql.SQLException;

import javax.jms.JMSException;
import javax.jms.Session;
import javax.jms.Topic;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;
import javax.jms.TopicSession;

import oracle.AQ.AQException;
import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;
import oracle.jms.AQjmsTopicPublisher;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class PublishTEQ {

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

        // publish message
        Topic topic = ((AQjmsSession) session).getTopic(username, topicName);
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