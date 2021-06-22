/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import io.opentracing.contrib.jms.TracingMessageProducer;
import oracle.jms.AQjmsConstants;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

import javax.jms.*;
import javax.sql.DataSource;
import java.sql.Connection;

import oracle.soda.OracleException;

class OrderServiceEventProducer {

    OrderResource orderResource;

    public OrderServiceEventProducer(OrderResource orderResource) {
        this.orderResource = orderResource;
    }

    String updateDataAndSendEvent(
            DataSource dataSource, String orderid, String itemid, String deliverylocation) throws Exception {
        System.out.println("updateDataAndSendEvent enter dataSource:" + dataSource +
                ", itemid:" + itemid + ", orderid:" + orderid +
                ",queueOwner:" + OrderResource.orderQueueOwner + "queueName:" + OrderResource.orderQueueName);
        TopicSession session = null;
        try {
            TopicConnectionFactory q_cf = AQjmsFactory.getTopicConnectionFactory(dataSource);
            TopicConnection q_conn = q_cf.createTopicConnection();


            session = q_conn.createTopicSession(true, Session.CLIENT_ACKNOWLEDGE);
            Connection jdbcConnection = ((AQjmsSession) session).getDBConnection();
            System.out.println("updateDataAndSendEvent jdbcConnection:" + jdbcConnection + " about to insertOrderViaSODA...");
            Order insertedOrder = insertOrderViaSODA(orderid, itemid, deliverylocation, jdbcConnection);
            if (OrderResource.crashAfterInsert) System.exit(-1);
            System.out.println("updateDataAndSendEvent insertOrderViaSODA complete about to send order message...");
            Topic topic = ((AQjmsSession) session).getTopic(OrderResource.orderQueueOwner, OrderResource.orderQueueName);
            System.out.println("updateDataAndSendEvent topic:" + topic);
            TextMessage objmsg = session.createTextMessage();
            TopicPublisher publisher = session.createPublisher(topic);
            TracingMessageProducer producer = new TracingMessageProducer(publisher, orderResource.getTracer());
            objmsg.setIntProperty("Id", 1);
            objmsg.setIntProperty("Priority", 2);
            String jsonString = JsonUtils.writeValueAsString(insertedOrder);
            objmsg.setText(jsonString);
            objmsg.setJMSCorrelationID("" + 1);
            objmsg.setJMSPriority(2);
            producer.send(topic, objmsg, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
//            publisher.publish(topic, objmsg, DeliveryMode.PERSISTENT,2, AQjmsConstants.EXPIRATION_NEVER);
            session.commit();
            System.out.println("updateDataAndSendEvent committed JSON order in database and sent message in the same tx with payload:" + jsonString);
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

    private Order insertOrderViaSODA(String orderid, String itemid, String deliverylocation,
                                    Connection jdbcConnection)
            throws OracleException {
        Order order = new Order(orderid, itemid, deliverylocation, "pending", "", "");
        new OrderDAO().create(jdbcConnection, order);
        return order;
    }

    void updateOrderViaSODA(Order order, Connection jdbcConnection)
            throws OracleException {
        new OrderDAO().update(jdbcConnection, order);
    }


    String deleteOrderViaSODA( DataSource dataSource, String orderid) throws Exception {
        try (Connection jdbcConnection = dataSource.getConnection()) {
            new OrderDAO().delete(jdbcConnection, orderid);
            return "deleteOrderViaSODA success";
        }
    }


    String dropOrderViaSODA( DataSource dataSource) throws Exception {
        try (Connection jdbcConnection = dataSource.getConnection()) {
            return new OrderDAO().drop(jdbcConnection);
        }
    }

    Order getOrderViaSODA( DataSource dataSource, String orderid) throws Exception {
        try (Connection jdbcConnection = dataSource.getConnection()) {
            return new OrderDAO().get(jdbcConnection, orderid);
        }
    }

}
