/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.helidon.data.examples;

import oracle.jdbc.internal.OraclePreparedStatement;
import oracle.jms.*;

import javax.jms.*;
import java.lang.IllegalStateException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

public class InventoryServiceOrderEventConsumer implements Runnable {

    private static final String DECREMENT_BY_ID =
            "update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";
    InventoryResource inventoryResource;
    Connection dbConnection;

    public InventoryServiceOrderEventConsumer(InventoryResource inventoryResource) {
        this.inventoryResource = inventoryResource;
    }

    @Override
    public void run() {
        System.out.println("Receive messages...");
        try {
            listenForOrderEvents();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void listenForOrderEvents() throws Exception {
        QueueConnectionFactory qcfact = AQjmsFactory.getQueueConnectionFactory(inventoryResource.atpInventoryPDB);
        QueueSession qsess = null;
        QueueConnection qconn = null;
        AQjmsConsumer consumer = null;

        boolean done = false;
        while (!done) {
            try {
                if (qconn == null || qsess == null ||  dbConnection ==null || dbConnection.isClosed()) {
                    qconn = qcfact.createQueueConnection(inventoryResource.inventoryuser, inventoryResource.inventorypw);
                    qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
                    qconn.start();
                    Queue queue = ((AQjmsSession) qsess).getQueue(inventoryResource.inventoryuser, inventoryResource.orderQueueName);
                    consumer = (AQjmsConsumer) qsess.createConsumer(queue);
                }
                if (consumer == null) continue;
                TextMessage orderMessage = (TextMessage) (consumer.receive(-1));  //todo address JMS-257: receive(long timeout) of javax.jms.MessageConsumer took more time than the network timeout configured at the java.sql.Connection.
                String txt = orderMessage.getText();
                System.out.println("txt " + txt);
                System.out.print("JMSPriority: " + orderMessage.getJMSPriority());
                System.out.println("Priority: " + orderMessage.getIntProperty("Priority"));
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
        String inventorylocation = evaluateInventory(session, itemid);
        Inventory inventory = new Inventory(orderid, itemid, inventorylocation, "beer"); //static suggestiveSale - represents an additional service/event
        String jsonString = JsonUtils.writeValueAsString(inventory);
        Topic inventoryTopic = session.getTopic(InventoryResource.inventoryuser, InventoryResource.inventoryQueueName);
        System.out.println("send inventory status message... jsonString:" + jsonString + " inventoryTopic:" + inventoryTopic);
        TextMessage objmsg = session.createTextMessage();
        TopicPublisher publisher = session.createPublisher(inventoryTopic);
        objmsg.setIntProperty("Id", 1);
        objmsg.setIntProperty("Priority", 2);
        objmsg.setText(jsonString);
        objmsg.setJMSCorrelationID("" + 2);
        objmsg.setJMSPriority(2);
        publisher.publish(inventoryTopic, objmsg, DeliveryMode.PERSISTENT, 2, AQjmsConstants.EXPIRATION_NEVER);
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
                return "inventorydoesnotexist";
            }
        }
    }


}
