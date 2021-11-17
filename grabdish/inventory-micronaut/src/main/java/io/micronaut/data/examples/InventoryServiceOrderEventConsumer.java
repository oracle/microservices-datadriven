/*

 **
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
package io.micronaut.data.examples;

//import com.fasterxml.jackson.databind.ObjectMapper;
import org.json.JSONObject;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jms.AQjmsConstants;
import oracle.jms.AQjmsConsumer;
import oracle.jms.AQjmsFactory;
import oracle.jms.AQjmsSession;

import javax.jms.*;
import javax.sql.DataSource;
import java.io.StringWriter;
import java.sql.*;
import java.sql.Connection;

public class InventoryServiceOrderEventConsumer implements Runnable {

    private static final String DECREMENT_BY_ID =
            "update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";
    public static final String INVENTORYDOESNOTEXIST = "inventorydoesnotexist";
    private DataSource atpInventoryPDB;
    Connection dbConnection;
    String inventoryuser = "inventoryuser", inventorypw = "Welcome12345", orderQueueName = "ORDERQUEUE", inventoryQueueName = "INVENTORYQUEUE";


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
            if (qconn == null || qsess == null || dbConnection == null || dbConnection.isClosed()) {
                qconn = qcfact.createQueueConnection(inventoryuser, inventorypw);
                qsess = qconn.createQueueSession(true, Session.CLIENT_ACKNOWLEDGE);
                qconn.start();
                Queue queue = ((AQjmsSession) qsess).getQueue(inventoryuser, orderQueueName);
                consumer = (AQjmsConsumer) qsess.createConsumer(queue);
            }
            TextMessage orderMessage = (TextMessage) (consumer.receive(-1));
            String txt = orderMessage.getText();
            System.out.println("txt " + txt);
//            {"orderid":"648","itemid":"sushi","deliverylocation":"780 PANORAMA DR,San Francisco,CA","status":"pending","inventoryLocation":"","suggestiveSale":""}
            JSONObject jsonObject = new JSONObject(txt);
            System.out.println("InventoryServiceOrderEventConsumer.listenForOrderEvents");
            System.out.println("InventoryServiceOrderEventConsumer.listenForOrderEvents jsonObject.getString(\"itemid\"):" + jsonObject.getString("itemid"));
            Order order = new Order(jsonObject.getString("orderid"),jsonObject.getString("itemid"),jsonObject.getString("deliverylocation"));
            //using JSONObject rather than jackson/reflectively accessed elements as it's somewhat more straightforward than... https://github.com/oracle/graal/issues/1022
//                ObjectMapper mapper = new ObjectMapper();
//                Order order = mapper.readValue(txt, Order.class);
//                Order order = JsonUtils.read(txt, Order.class);
                System.out.print(" orderid:" + order.getOrderid());
                System.out.print(" itemid:" + order.getItemid());
                updateDataAndSendEventOnInventory((AQjmsSession) qsess, order.getOrderid(), order.getItemid());
            if (qsess != null) qsess.commit();
            System.out.println("message sent");

        }
    }

    private void updateDataAndSendEventOnInventory(AQjmsSession session, String orderid, String itemid) throws Exception {
        String inventorylocation = evaluateInventory(session, itemid);
//        Inventory inventory = new Inventory(orderid, itemid, inventorylocation, "beer"); //static suggestiveSale - represents an additional service/event
//        String jsonString = JsonUtils.writeValueAsString(inventory);
        String jsonString =
                new JSONObject().put("orderid", orderid).put("itemid", itemid)
                        .put("inventorylocation", inventorylocation).put("suggestiveSale", "beer").toString();
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
