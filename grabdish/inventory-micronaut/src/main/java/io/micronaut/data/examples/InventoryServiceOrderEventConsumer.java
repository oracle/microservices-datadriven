/*
 
 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.micronaut.data.examples;

import oracle.jdbc.OraclePreparedStatement;
import oracle.jms.AQjmsConstants;
import oracle.jms.AQjmsConsumer;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

import javax.jms.*;
import javax.sql.DataSource;
import java.sql.*;
import java.sql.Connection;

public class InventoryServiceOrderEventConsumer implements Runnable {

    private static final String DECREMENT_BY_ID =
            "update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";
    public static final String INVENTORYDOESNOTEXIST = "inventorydoesnotexist";
    private DataSource atpInventoryPDB;
    Connection dbConnection;
    String inventoryuser = "inventoryuser", inventorypw ="Welcome12345", orderQueueName = "ORDERQUEUE", inventoryQueueName = "INVENTORYQUEUE";


    public InventoryServiceOrderEventConsumer(DataSource atpInventoryPDB) {
        this.atpInventoryPDB = atpInventoryPDB;
    }


    @Override
    public void run() {
        System.out.println("Receive messages... ");
        try {
            listenForOrderEvents();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public void listenForOrderEvents() throws Exception {
        QueueConnectionFactory qcfact = AQjmsFactory.getQueueConnectionFactory(atpInventoryPDB);
        QueueSession qsess = null;
        QueueConnection qconn = null;
        AQjmsConsumer consumer = null;
        boolean done = false;
        while (!done) {
          //  try {
                if (qconn == null || qsess == null ||  dbConnection ==null || dbConnection.isClosed()) {
                    qconn = qcfact.createQueueConnection(inventoryuser, inventorypw);
                    qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
                    qconn.start();
                    Queue queue = ((AQjmsSession) qsess).getQueue(inventoryuser, orderQueueName);
                    consumer = (AQjmsConsumer) qsess.createConsumer(queue);
                }
                TextMessage orderMessage = (TextMessage) (consumer.receive(-1));
                String txt = orderMessage.getText();
                System.out.println("txt " + txt);
                System.out.print(" Message: " + orderMessage.getIntProperty("Id"));
                Order order = JsonUtils.read(txt, Order.class);
                System.out.print(" orderid:" + order.getOrderid());
                System.out.print(" itemid:" + order.getItemid());
                updateDataAndSendEventOnInventory((AQjmsSession) qsess, order.getOrderid(), order.getItemid());
                if(qsess!=null) qsess.commit();
                System.out.println("message sent");

        }
    }

    private void updateDataAndSendEventOnInventory(AQjmsSession session, String orderid, String itemid) throws Exception {
        String inventorylocation = evaluateInventory(session, itemid);
        Inventory inventory = new Inventory(orderid, itemid, inventorylocation, "beer"); //static suggestiveSale - represents an additional service/event
          String jsonString = JsonUtils.writeValueAsString(inventory);
        Topic inventoryTopic = session.getTopic(inventoryuser, inventoryQueueName);
        System.out.println("send inventory status message... jsonString:" + jsonString + " inventoryTopic:" + inventoryTopic);
        TextMessage objmsg = session.createTextMessage();
        TopicPublisher publisher = session.createPublisher(inventoryTopic);
        objmsg.setText(jsonString);
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
                return INVENTORYDOESNOTEXIST;
            }
        }
    }


}
