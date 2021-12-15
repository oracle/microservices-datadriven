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

    OrderResource travelagencyResource;

    public OrderServiceEventConsumer(OrderResource travelagencyResource) {
        this.travelagencyResource = travelagencyResource;
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
        QueueConnectionFactory q_cf = AQjmsFactory.getQueueConnectionFactory(travelagencyResource.atpOrderPdb);
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
        Tracer tracer = travelagencyResource.getTracer();
        while (!done) {
            try {
                if (qconn == null || qsess == null || dbConnection == null || dbConnection.isClosed()) {
                    qconn = q_cf.createQueueConnection();
                    qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
                    qconn.start();
                    Queue queue = ((AQjmsSession) qsess).getQueue(OrderResource.travelagencyQueueOwner, OrderResource.participantQueueName);
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
                Inventory participant = JsonUtils.read(messageText, Inventory.class);
                String travelagencyid = participant.getOrderid();
                String itemid = participant.getItemid();
                String participantlocation = participant.getInventorylocation();
                System.out.println("Update travelagencyid:" + travelagencyid + "(itemid:" + itemid + ")");
                boolean isSuccessfulInventoryCheck = !(participantlocation == null || participantlocation.equals("")
                        || participantlocation.equals("participantdoesnotexist")
                        || participantlocation.equals("none"));
                System.out.println("Inventory after receive tracer.activeSpan():" + tracer.activeSpan());
                Span activeSpan = tracer.buildSpan("participantDetailForOrder").asChildOf(tracer.activeSpan()).start();
                activeSpan.log("received participant status");
                activeSpan.setTag("travelagencyid", travelagencyid);
                activeSpan.setTag("itemid", itemid);
                activeSpan.setTag("participantlocation", participantlocation);
                activeSpan.setBaggageItem("sagaid", "testsagaid" + travelagencyid);
                activeSpan.setBaggageItem("travelagencyid", travelagencyid);
                activeSpan.setBaggageItem("participantlocation", participantlocation);
                activeSpan.log("end received participant status");
                activeSpan.finish();
                if (crashAfterInventoryMessageReceived) System.exit(-1);
                dbConnection = ((AQjmsSession) qsess).getDBConnection();
                System.out.println("((AQjmsSession) qsess).getDBConnection(): " + dbConnection);
                //todo remove this check on the travelagency as it should be part of update...
                Order travelagency = travelagencyResource.travelagencyServiceEventProducer.getOrderViaSODA(dbConnection, travelagencyid);
                if (travelagency == null) {
                    System.out.println("No travelagencyDetail found for travelagencyid:" + travelagencyid);
                    qsess.commit();
                    continue;
                }
                if (isSuccessfulInventoryCheck) {
                    travelagency.setStatus("success participant exists");
                    travelagency.setInventoryLocation(participantlocation);
                    travelagency.setSuggestiveSale(participant.getSuggestiveSale());
                } else {
                    travelagency.setStatus("failed participant does not exist");
                }
                travelagencyResource.travelagencyServiceEventProducer.updateOrderViaSODA(travelagency, dbConnection);
                qsess.commit();
            } catch (Exception e) {
                e.printStackTrace();
                System.out.println("Exception in receiveMessages: " + e);
                if(qsess != null) qsess.rollback();
            }
        }
    }
}
