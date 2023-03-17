// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

package com.example.aq;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import com.example.aqautoconfig.AQProperties;
import org.springframework.beans.factory.annotation.Autowired;

import javax.jms.Session;
import javax.jms.Topic;
import javax.jms.TopicConnection;
import javax.jms.TopicConnectionFactory;
import javax.jms.TopicSession;

import oracle.jms.AQjmsAgent;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;
import oracle.jms.AQjmsTextMessage;
import oracle.jms.AQjmsTopicPublisher;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

@Component
@Slf4j
public class AQComponent {
    
    private AQProperties properties;

    public AQComponent(AQProperties properties) {
        this.properties = properties;
    }

    public void sendMessage(String data) {
        System.out.println(
            "Hi there!  This is AQComponent!\n" +
            "Here is my configuration: \n" +
            "  url = " + properties.getUrl() + "\n" +
            "  username = " + properties.getUsername() + "\n" +
            "  password = " + properties.getPassword() + "\n" +
            "  queueName " + properties.getQueue() + "\n" +
            "Now I would send a message containing: " + data
        );

        try {
            System.out.println("connect to db");
            PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
            ds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
            ds.setURL(properties.getUrl());
            ds.setUser(properties.getUsername());
            ds.setPassword(properties.getPassword());

            System.out.println("create tcf");
            TopicConnectionFactory tcf = AQjmsFactory.getTopicConnectionFactory(ds);
            TopicConnection conn = tcf.createTopicConnection();
            conn.start();
            TopicSession session = (AQjmsSession) 
            conn.createSession(true, Session.AUTO_ACKNOWLEDGE);

            // publish message
            System.out.println("publish message");
            Topic topic = ((AQjmsSession) session).getTopic(properties.getUsername(), properties.getQueue());
            AQjmsTopicPublisher publisher = (AQjmsTopicPublisher) session.createPublisher(topic);

            AQjmsTextMessage message = (AQjmsTextMessage) 
            session.createTextMessage(data);
            publisher.publish(message, new AQjmsAgent[] { new AQjmsAgent("bob", null) });
            session.commit();

            // clean up
            System.out.println("clean up");
            publisher.close();
            session.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        }

}