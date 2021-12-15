/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import io.opentracing.Span;
import io.opentracing.contrib.jms2.TracingMessageProducer;
import oracle.jdbc.OracleConnection;
import oracle.jms.AQjmsConstants;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

import javax.jms.*;
import javax.sql.DataSource;
import java.sql.Connection;

import oracle.soda.OracleException;

class OrderServiceEventProducer {

    OrderResource travelagencyResource;

    public OrderServiceEventProducer(OrderResource travelagencyResource) {
        this.travelagencyResource = travelagencyResource;
    }

    String updateDataAndSendEvent(
            DataSource dataSource, String travelagencyid, String itemid, String deliverylocation, Span activeSpan, String spanIdForECID) throws Exception {
        System.out.println("updateDataAndSendEvent enter dataSource:" + dataSource +
                ", itemid:" + itemid + ", travelagencyid:" + travelagencyid +
                ",queueOwner:" + OrderResource.travelagencyQueueOwner + "queueName:" + OrderResource.travelagencyQueueName);
        TopicSession session = null;
        try {
            TopicConnectionFactory q_cf = AQjmsFactory.getTopicConnectionFactory(dataSource);
            TopicConnection q_conn = q_cf.createTopicConnection();
            session = q_conn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
            OracleConnection jdbcConnection = ((OracleConnection)((AQjmsSession) session).getDBConnection());
            System.out.println("OrderServiceEventProducer.updateDataAndSendEvent activespan ecid=" + activeSpan);
            short seqnum = 20;
            String[] metric = new String[OracleConnection.END_TO_END_STATE_INDEX_MAX];
            metric[OracleConnection.END_TO_END_ACTION_INDEX] = "travelagencyservice_action_placeOrder";
            metric[OracleConnection.END_TO_END_MODULE_INDEX] = "travelagencyservice_module";
            metric[OracleConnection.END_TO_END_CLIENTID_INDEX] = "travelagencyservice_clientid";
            metric[OracleConnection.END_TO_END_ECID_INDEX] = spanIdForECID; //for log to trace
            activeSpan.setBaggageItem("ecid", spanIdForECID); //for trace to log
            jdbcConnection.setEndToEndMetrics(metric,seqnum);//  todo instead use  conn.setClientInfo();
            System.out.println("updateDataAndSendEvent jdbcConnection:" + jdbcConnection + " activeSpan:" + activeSpan + " about to insertOrderViaSODA...");
            Order insertedOrder = insertOrderViaSODA(travelagencyid, itemid, deliverylocation, jdbcConnection);
            if (OrderResource.crashAfterInsert) System.exit(-1);
            System.out.println("updateDataAndSendEvent insertOrderViaSODA complete about to send travelagency message...");
            Topic topic = ((AQjmsSession) session).getTopic(OrderResource.travelagencyQueueOwner, OrderResource.travelagencyQueueName);
            System.out.println("updateDataAndSendEvent topic:" + topic);
            TextMessage objmsg = session.createTextMessage();
            TracingMessageProducer producer = new TracingMessageProducer(session.createPublisher(topic), travelagencyResource.getTracer());
            objmsg.setIntProperty("Id", 1);
            objmsg.setIntProperty("Priority", 2);
            String jsonString = JsonUtils.writeValueAsString(insertedOrder);
            objmsg.setText(jsonString);
            objmsg.setJMSPriority(2);
            producer.send(topic, objmsg, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
//            publisher.publish(topic, objmsg, DeliveryMode.PERSISTENT,2, AQjmsConstants.EXPIRATION_NEVER);
            session.commit();
            System.out.println("updateDataAndSendEvent committed JSON travelagency in database and sent message in the same tx with payload:" + jsonString);
            return topic.toString();
        } catch (Exception e) {
            System.out.println("updateDataAndSendEvent failed with exception:" + e);
            if (session != null) {
                try {
                    session.rollback();
                } catch (JMSException e1) {
                    System.out.println("updateDataAndSendEvent session.rollback() failed:" + e1);
                } finally {
                    throw e;
                }
            }
            throw e;
        } finally {
            if (session != null) session.close();
        }
    }

    private Order insertOrderViaSODA(String travelagencyid, String itemid, String deliverylocation,
                                    Connection jdbcConnection)  throws OracleException {
        Order travelagency = new Order(travelagencyid, itemid, deliverylocation, "pending", "", "");
        new OrderDAO().create(jdbcConnection, travelagency);
        return travelagency;
    }

    void updateOrderViaSODA(Order travelagency, Connection jdbcConnection) throws OracleException {
        new OrderDAO().update(jdbcConnection, travelagency);
    }

    String deleteOrderViaSODA( DataSource dataSource, String travelagencyid) throws Exception {
        try (Connection jdbcConnection = dataSource.getConnection()) {
            new OrderDAO().delete(jdbcConnection, travelagencyid);
            return "deleteOrderViaSODA success";
        }
    }

    String dropOrderViaSODA( DataSource dataSource) throws Exception {
        try (Connection jdbcConnection = dataSource.getConnection()) {
            return new OrderDAO().drop(jdbcConnection);
        }
    }

    Order getOrderViaSODA( Connection jdbcConnection, String travelagencyid) throws Exception {
            return new OrderDAO().get(jdbcConnection, travelagencyid);
    }
}
