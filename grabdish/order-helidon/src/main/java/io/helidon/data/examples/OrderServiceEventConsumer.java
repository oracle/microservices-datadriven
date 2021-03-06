/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import io.opentracing.contrib.jms.common.TracingMessageConsumer;
import oracle.jms.AQjmsConsumer;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

import javax.jms.*;
import java.sql.Connection;

public class OrderServiceEventConsumer implements Runnable {

    OrderResource orderResource;
    Connection dbConnection;

    public OrderServiceEventConsumer(OrderResource orderResource) {
        this.orderResource = orderResource;
    }

    @Override
    public void run() {
        System.out.println("Receive messages...");
        try {
            dolistenForMessages();
        } catch (JMSException e) {
            e.printStackTrace();
        }
    }

    public void dolistenForMessages() throws JMSException {
        QueueConnectionFactory q_cf = AQjmsFactory.getQueueConnectionFactory(orderResource.atpOrderPdb);
        QueueSession qsess = null;
        QueueConnection qconn = null;
        MessageConsumer consumer = null;
        //python (and likely nodejs) message causes javax.jms.MessageFormatException: JMS-117: Conversion failed - invalid property type
        //due to message.getObjectProperty(key) here...
        // https://github.com/opentracing-contrib/java-jms/blob/c9c445c374159cd8eadcbc9af0994a788baf0c5c/opentracing-jms-common/src/main/java/io/opentracing/contrib/jms/common/JmsTextMapExtractAdapter.java#L41
//        TracingMessageConsumer tracingMessageConsumer = null;
        boolean done = false;
        while (!done) {
            try {
                if (qconn == null || qsess == null || dbConnection == null || dbConnection.isClosed()) {
                    qconn = q_cf.createQueueConnection();
                    qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
                    qconn.start();
                    Queue queue = ((AQjmsSession) qsess).getQueue(OrderResource.orderQueueOwner, OrderResource.inventoryQueueName);
                    consumer = (AQjmsConsumer) qsess.createConsumer(queue);
//                    tracingMessageConsumer = new TracingMessageConsumer(consumer, orderResource.getTracer());
                }
//                if (tracingMessageConsumer == null || qsess == null) continue;
                if (consumer == null || qsess == null) continue;
//                TextMessage textMessage = (TextMessage) tracingMessageConsumer.receive(-1);
                TextMessage textMessage = (TextMessage) consumer.receive(-1);
                String messageText = textMessage.getText();
                System.out.println("messageText " + messageText);
                System.out.print(" Pri: " + textMessage.getJMSPriority());
                Inventory inventory = JsonUtils.read(messageText, Inventory.class);
                String orderid = inventory.getOrderid();
                String itemid = inventory.getItemid();
                String inventorylocation = inventory.getInventorylocation();
                System.out.println("Lookup orderid:" + orderid + "(itemid:" + itemid + ")");
                Order order = orderResource.orderServiceEventProducer.getOrderViaSODA(orderResource.atpOrderPdb, orderid);
                if (order == null) {
                    System.out.println("No orderDetail found for orderid:" + orderid);
                    qsess.commit();
                    continue;
                }
                boolean isSuccessfulInventoryCheck = !(inventorylocation == null || inventorylocation.equals("")
                        || inventorylocation.equals("inventorydoesnotexist")
                        || inventorylocation.equals("none"));
                if (isSuccessfulInventoryCheck) {
                    order.setStatus("success inventory exists");
                    order.setInventoryLocation(inventorylocation);
                    order.setSuggestiveSale(inventory.getSuggestiveSale());
                } else {
                    order.setStatus("failed inventory does not exist");
                }
                dbConnection = ((AQjmsSession) qsess).getDBConnection();
                orderResource.orderServiceEventProducer.updateOrderViaSODA(order, dbConnection);
                System.out.println("((AQjmsSession) qsess).getDBConnection(): " + ((AQjmsSession) qsess).getDBConnection());
                qsess.commit();
            } catch (Exception e) {
                e.printStackTrace();
                System.out.println("Exception in receiveMessages: " + e);
                if(qsess != null) qsess.rollback();
            }
        }
    }
}
