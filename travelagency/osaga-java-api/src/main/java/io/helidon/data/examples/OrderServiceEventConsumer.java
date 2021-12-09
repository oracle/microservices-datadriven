/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import io.opentracing.Span;
import io.opentracing.Tracer;
//import io.opentracing.contrib.jms.common.TracingMessageConsumer;
import oracle.jms.AQjmsConsumer;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

import javax.jms.*;
import java.sql.Connection;
import java.util.Enumeration;

import static io.helidon.data.examples.OrderResource.crashAfterInventoryMessageReceived;

public class OrderServiceEventConsumer implements Runnable {

    OrderResource orderResource;

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
//        TracingMessageConsumer consumer = null;
        Connection dbConnection = null;
        //python (and likely nodejs) message causes javax.jms.MessageFormatException: JMS-117: Conversion failed - invalid property type
        //due to message.getObjectProperty(key) here...
        // https://github.com/opentracing-contrib/java-jms/blob/c9c445c374159cd8eadcbc9af0994a788baf0c5c/opentracing-jms-common/src/main/java/io/opentracing/contrib/jms/common/JmsTextMapExtractAdapter.java#L41
//        TracingMessageConsumer tracingMessageConsumer = null;
        boolean done = false;
        Tracer tracer = orderResource.getTracer();
        while (!done) {
            try {
                if (qconn == null || qsess == null || dbConnection == null || dbConnection.isClosed()) {
                    qconn = q_cf.createQueueConnection();
                    qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
                    qconn.start();
                    Queue queue = ((AQjmsSession) qsess).getQueue(OrderResource.orderQueueOwner, OrderResource.inventoryQueueName);
                    consumer = (AQjmsConsumer) qsess.createConsumer(queue);
//                    consumer = new TracingMessageConsumer(qsess.createConsumer(queue), tracer);
                }
//                if (tracingMessageConsumer == null || qsess == null) continue;
                if (consumer == null || qsess == null) continue;
                System.out.println("Inventory before receive tracer.activeSpan():" + tracer.activeSpan());
                TextMessage textMessage = (TextMessage) consumer.receive(-1);
//                TextMessage textMessage = (TextMessage) consumer.receive(-1);
                String messageText = textMessage.getText();
                System.out.println("messageText " + messageText);
                Inventory inventory = JsonUtils.read(messageText, Inventory.class);
                String orderid = inventory.getOrderid();
                String itemid = inventory.getItemid();
                String inventorylocation = inventory.getInventorylocation();
                System.out.println("Update orderid:" + orderid + "(itemid:" + itemid + ")");
                boolean isSuccessfulInventoryCheck = !(inventorylocation == null || inventorylocation.equals("")
                        || inventorylocation.equals("inventorydoesnotexist")
                        || inventorylocation.equals("none"));
                System.out.println("Inventory after receive tracer.activeSpan():" + tracer.activeSpan());
                Span activeSpan = tracer.buildSpan("inventoryDetailForOrder").asChildOf(tracer.activeSpan()).start();
                activeSpan.log("received inventory status");
                activeSpan.setTag("orderid", orderid);
                activeSpan.setTag("itemid", itemid);
                activeSpan.setTag("inventorylocation", inventorylocation);
                activeSpan.setBaggageItem("sagaid", "testsagaid" + orderid);
                activeSpan.setBaggageItem("orderid", orderid);
                activeSpan.setBaggageItem("inventorylocation", inventorylocation);
                activeSpan.log("end received inventory status");
                activeSpan.finish();
                if (crashAfterInventoryMessageReceived) System.exit(-1);
                dbConnection = ((AQjmsSession) qsess).getDBConnection();
                System.out.println("((AQjmsSession) qsess).getDBConnection(): " + dbConnection);
                //todo remove this check on the order as it should be part of update...
                Order order = orderResource.orderServiceEventProducer.getOrderViaSODA(dbConnection, orderid);
                if (order == null) {
                    System.out.println("No orderDetail found for orderid:" + orderid);
                    qsess.commit();
                    continue;
                }
                if (isSuccessfulInventoryCheck) {
                    order.setStatus("success inventory exists");
                    order.setInventoryLocation(inventorylocation);
                    order.setSuggestiveSale(inventory.getSuggestiveSale());
                } else {
                    order.setStatus("failed inventory does not exist");
                }
                orderResource.orderServiceEventProducer.updateOrderViaSODA(order, dbConnection);
                qsess.commit();
            } catch (Exception e) {
                e.printStackTrace();
                System.out.println("Exception in receiveMessages: " + e);
                if(qsess != null) qsess.rollback();
            }
        }
    }
}
