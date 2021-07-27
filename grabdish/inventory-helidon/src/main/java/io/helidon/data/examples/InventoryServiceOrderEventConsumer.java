/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import io.opentracing.Span;
import io.opentracing.contrib.jms2.TracingMessageProducer;
import io.opentracing.contrib.jms.common.TracingMessageConsumer;
import oracle.jdbc.internal.OraclePreparedStatement;
import oracle.jms.*;
import org.eclipse.microprofile.metrics.Counter;
import org.eclipse.microprofile.metrics.Metadata;
import org.eclipse.microprofile.metrics.MetricType;

import javax.jms.*;
import java.lang.IllegalStateException;
import java.sql.*;
import java.sql.Connection;

public class InventoryServiceOrderEventConsumer implements Runnable {

    private static final String DECREMENT_BY_ID =
            "update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";
    public static final String INVENTORYDOESNOTEXIST = "inventorydoesnotexist";
    InventoryResource inventoryResource;
    Connection dbConnection;

    public InventoryServiceOrderEventConsumer(InventoryResource inventoryResource) {
        this.inventoryResource = inventoryResource;
    }

    @Override
    public void run() {
        boolean isPLSQL = Boolean.valueOf(System.getProperty("isPLSQL", "false"));
        boolean isRollback = Boolean.valueOf(System.getProperty("isRollback", "false"));
        boolean isAutoCommit = Boolean.valueOf(System.getProperty("isAutoCommit", "false"));
        System.out.println("Receive messages... isPLSQL:" + isPLSQL);
        System.out.println("... isRollback:" + isRollback);
        System.out.println("... isAutoCommit:" + isAutoCommit);
        try {
            if (isPLSQL)listenForOrderEventsPLSQL(isRollback, isAutoCommit);
            else listenForOrderEvents();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void listenForOrderEventsPLSQL(boolean isRollback, boolean isAutoCommit) throws Exception {
        Connection connection = inventoryResource.atpInventoryPDB.getConnection();
    if(!isAutoCommit)    connection.setAutoCommit(false);
        while (true) {
            System.out.println("InventoryServiceOrderEventConsumer.listenForOrderEvents with sproc");
            CallableStatement cstmt = null;
            String SQL = "{call dequeueOrderMessage (?)}";
            cstmt = connection.prepareCall(SQL);
            cstmt.registerOutParameter(1, Types.VARCHAR);
//            cstmt.registerOutParameter("p_orderInfo", Types.VARCHAR);
            boolean hadResults = cstmt.execute();
            System.out.println("InventoryServiceOrderEventConsumer.listenForOrderEvents hadResults:" + hadResults);
            while (hadResults) {
                ResultSet rs = cstmt.getResultSet();
                hadResults = cstmt.getMoreResults();
            }
            String outputValue = cstmt.getString(1);
            if (!isAutoCommit) {
                if (isRollback) connection.rollback();
                else connection.commit();
            }
            System.out.println("InventoryServiceOrderEventConsumer.listenForOrderEvents outputValue:" + outputValue);
        }
    }

    public void listenForOrderEvents() throws Exception {
        QueueConnectionFactory qcfact = AQjmsFactory.getQueueConnectionFactory(inventoryResource.atpInventoryPDB);
        QueueSession qsess = null;
        QueueConnection qconn = null;
        TracingMessageConsumer tracingMessageConsumer = null;
        boolean done = false;
        while (!done) {
            try {
                if (qconn == null || qsess == null ||  dbConnection ==null || dbConnection.isClosed()) {
                    qconn = qcfact.createQueueConnection(inventoryResource.inventoryuser, inventoryResource.inventorypw);
                    qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
                    qconn.start();
                    Queue queue = ((AQjmsSession) qsess).getQueue(inventoryResource.inventoryuser, inventoryResource.orderQueueName);
                    AQjmsConsumer consumer = (AQjmsConsumer) qsess.createConsumer(queue);
                    tracingMessageConsumer = new TracingMessageConsumer(consumer, inventoryResource.getTracer());
                }
                if (tracingMessageConsumer == null) continue;
                TextMessage orderMessage = (TextMessage) (tracingMessageConsumer.receive(-1));
                String txt = orderMessage.getText();
                System.out.println("txt " + txt);
                System.out.print(" Message: " + orderMessage.getIntProperty("Id"));
                Order order = JsonUtils.read(txt, Order.class);
                System.out.print(" orderid:" + order.getOrderid());
                System.out.print(" itemid:" + order.getItemid());
                updateDataAndSendEventOnInventory((AQjmsSession) qsess, order.getOrderid(), order.getItemid());
                if(qsess!=null) qsess.commit();
                System.out.println("message sent");
            } catch (IllegalStateException e) {
                System.out.println("IllegalStateException in receiveMessages: " + e + " unrecognized message will be ignored");
                if (qsess != null) qsess.commit(); //drain unrelated messages - todo add selector for this instead
            } catch (Exception e) {
                System.out.println("Error in receiveMessages: " + e);
                if (qsess != null) qsess.rollback();
            }
        }
    }

    private void updateDataAndSendEventOnInventory(AQjmsSession session, String orderid, String itemid) throws Exception {
        if (inventoryResource.crashAfterOrderMessageReceived) System.exit(-1);
        String inventorylocation = evaluateInventory(session, itemid);
        Inventory inventory = new Inventory(orderid, itemid, inventorylocation, "beer"); //static suggestiveSale - represents an additional service/event
        Span activeSpan = inventoryResource.getTracer().buildSpan("inventorylocation").asChildOf(inventoryResource.getTracer().activeSpan()).start();
        activeSpan.log("begin placing order"); // logs are for a specific moment or event within the span (in contrast to tags which should apply to the span regardless of time).
        activeSpan.setTag("orderid", orderid); //tags are annotations of spans in order to query, filter, and comprehend trace data
        activeSpan.setTag("itemid", itemid);
        activeSpan.setTag("inventorylocation", inventorylocation); // https://github.com/opentracing/specification/blob/master/semantic_conventions.md
        activeSpan.setTag("dbConnection.getMetaData()", dbConnection.getMetaData().toString()); // https://github.com/opentracing/specification/blob/master/semantic_conventions.md
        activeSpan.setBaggageItem("sagaid", "testsagaid" + orderid); //baggage is part of SpanContext and carries data across process boundaries for access throughout the trace
        activeSpan.setBaggageItem("orderid", orderid);
        activeSpan.setBaggageItem("inventorylocation", inventorylocation);
        if (inventorylocation.equals(INVENTORYDOESNOTEXIST)) {
            System.out.println("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory increment INVENTORYDOESNOTEXIST metric");
            Metadata metadata = Metadata.builder()
                    .withName(INVENTORYDOESNOTEXIST + "Count")
                    .withType(MetricType.COUNTER)
                    .build();
            Counter metric = inventoryResource.getMetricRegistry().counter(metadata);
            metric.inc(1);
        }
        String jsonString = JsonUtils.writeValueAsString(inventory);
        Topic inventoryTopic = session.getTopic(InventoryResource.inventoryuser, InventoryResource.inventoryQueueName);
        System.out.println("send inventory status message... jsonString:" + jsonString + " inventoryTopic:" + inventoryTopic);
        if (inventoryResource.crashAfterOrderMessageProcessed) System.exit(-1);
        TextMessage objmsg = session.createTextMessage();
//        TopicPublisher publisher = session.createPublisher(inventoryTopic);
        TracingMessageProducer producer = new TracingMessageProducer(session.createPublisher(inventoryTopic), inventoryResource.getTracer());
        objmsg.setText(jsonString);
//        publisher.publish(inventoryTopic, objmsg, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
        producer.send(inventoryTopic, objmsg, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
    }

    private String evaluateInventory(AQjmsSession session, String id) throws JMSException, SQLException {
        dbConnection = session.getDBConnection();
        System.out.println("-------------->evaluateInventory connection:" + dbConnection +
                "Session:" + session + " check inventory for inventoryid:" + id);
        try (OraclePreparedStatement st = (OraclePreparedStatement) dbConnection.prepareStatement(DECREMENT_BY_ID)) {
            st.setString(1, id);
            st.registerReturnParameter(2, Types.VARCHAR);
            int i = st.executeUpdate();
            ResultSet res = st.getReturnResultSet();
            if (i > 0 && res.next()) {
                String location = res.getString(1);
                System.out.println("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} location {" + location + "}");
                return location;
            } else {
                System.out.println("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} inventorydoesnotexist");
                return INVENTORYDOESNOTEXIST;
            }
        }
    }


}
