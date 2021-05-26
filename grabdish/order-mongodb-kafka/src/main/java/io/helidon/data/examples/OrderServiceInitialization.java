/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import oracle.AQ.AQQueueTable;
import oracle.AQ.AQQueueTableProperty;
import oracle.jms.AQjmsDestination;
import oracle.jms.AQjmsDestinationProperty;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

import javax.jms.*;
import javax.sql.DataSource;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;

// this could also go in an initContainer(s) or some such but is convenient here
public class OrderServiceInitialization {

    public Object createQueue(DataSource aqDataSource, String queueOwner, String queueName, String msgType) throws Exception {
        System.out.println("create queue queueName:" + queueName);
        QueueConnectionFactory q_cf = AQjmsFactory.getQueueConnectionFactory(aqDataSource);
        QueueConnection q_conn = q_cf.createQueueConnection();
        Session session = q_conn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
        AQQueueTable q_table = null;
        AQQueueTableProperty qt_prop =
                new AQQueueTableProperty(
                        msgType.equals("map") ? "SYS.AQ$_JMS_MAP_MESSAGE":"SYS.AQ$_JMS_TEXT_MESSAGE" )  ;
        q_table = ((AQjmsSession) session).createQueueTable(queueOwner, queueName, qt_prop);
        Queue queue = ((AQjmsSession) session).createQueue(q_table, queueName, new AQjmsDestinationProperty());
        ((AQjmsDestination)queue).start(session, true, true);
        System.out.println("create queue successful for queue:" + queue.toString());
        return "createOrderQueue successful for queue:" + queue.toString();
    }

    public Object createTopic(DataSource aqDataSource, String queueOwner, String queueName, String msgType) throws Exception {
        System.out.println("create queue queueName:" + queueName);
        TopicConnectionFactory topicConnectionFactory = AQjmsFactory.getTopicConnectionFactory(aqDataSource);
        TopicConnection topicConnection = topicConnectionFactory.createTopicConnection();
        Session session = topicConnection.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
        AQQueueTable q_table = null;
        AQQueueTableProperty qt_prop =
                new AQQueueTableProperty(
                        msgType.equals("map") ? "SYS.AQ$_JMS_MAP_MESSAGE":"SYS.AQ$_JMS_TEXT_MESSAGE" )  ;
        q_table = ((AQjmsSession) session).createQueueTable(queueOwner, queueName, qt_prop);
        Topic topic = ((AQjmsSession) session).createTopic(q_table, queueName, new AQjmsDestinationProperty());
        ((AQjmsDestination)topic).start(session, true, true);
        System.out.println("create topic successful for queue:" + topic.toString());
        return "createOrderTopic successful for queue:" + topic.toString();
    }

    public Object createOrderQueueUsingPLSQL(Connection connection, String queueName) throws SQLException {
        System.out.println("--->Order createOrderQueueUsingPLSQL...");
        String tableCreateSQL = "BEGIN dbms_aqadm.create_queue_table( queue_table=>'MY_QUEUE_TABLE' " +
                "                             , queue_payload_type=>'SYS.AQ$_JMS_TEXT_MESSAGE' " +
                "                             , multiple_consumers=>false); " +
                "END;";
        CallableStatement cStmt = connection.prepareCall(tableCreateSQL);
        cStmt.execute();
        System.out.println("--->Order createqueue...");
        String queueCreateSQL = "BEGIN " +
                " dbms_aqadm.create_queue( " +
                " queue_name => '" + queueName + "' " +
                ",queue_table => '" + queueName + "' " +
                ",comment => '" + queueName + " Queue: Routes the messages from...'); " +
                "dbms_aqadm.start_queue(queue_name=>'" + queueName + "'); " +
                "END;";
        cStmt = connection.prepareCall(queueCreateSQL);
        cStmt.execute();
        return "order queue created successfully";
    }

}
