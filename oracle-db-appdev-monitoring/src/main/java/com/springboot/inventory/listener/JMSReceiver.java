package com.springboot.inventory.listener;

import javax.jms.JMSException;

import oracle.jdbc.internal.OraclePreparedStatement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import com.springboot.inventory.model.Inventory;
import com.springboot.inventory.model.Order;
import com.springboot.inventory.service.SupplierService;
import com.springboot.inventory.util.JsonUtils;

import oracle.jms.AQjmsSession;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

@Component
public class JMSReceiver {

	@Autowired
	JmsTemplate jmsTemplate;

	@Autowired
	SupplierService supplierService;
	
	@Autowired
	private Environment environment;
	
    String queueOwner = System.getenv("db_queueOwner"); // environment.getProperty("db_queueOwner");
    String orderQueueName = System.getenv("db_orderQueueName"); // environment.getProperty("db_orderQueueName");
    String inventoryQueueName = System.getenv("db_inventoryQueueName"); // environment.getProperty("db_inventoryQueueName");

	private Connection dbConnection;
	private static final String DECREMENT_BY_ID =
			"update inventory set inventorycount = inventorycount - 1 where inventoryid = ? and inventorycount > 0 returning inventorylocation into ?";
	public static final String INVENTORYDOESNOTEXIST = "inventorydoesnotexist";
	Logger logger = LoggerFactory.getLogger(JMSReceiver.class);

	@JmsListener(destination = "AQ.orderqueue", containerFactory = "topicConnectionFactory")
	public void listenOrderEvent(String message, AQjmsSession session) throws Exception {
		logger.info("Received Message Session: " + session + " orderMessage :" + message);
		Order order = JsonUtils.read(message, Order.class);
		String location = evaluateInventory(session, order.getItemid());
		logger.info("order :" + order + " location:" + location);
		inventoryEvent(order.getOrderid(), order.getItemid(), location, session);
	}

	public void inventoryEvent(String orderid, String itemid, String inventorylocation, AQjmsSession session) throws JMSException {
		Inventory inventory = new Inventory(orderid, itemid, inventorylocation, "beer");
		String jsonString = JsonUtils.writeValueAsString(inventory);
		logger.info("Sending reply for orderId :" + orderid + " itemid:" + itemid + " inventorylocation:" + inventorylocation+ " jsonString:" + jsonString+ " inventoryQueueName:" + inventoryQueueName);
		jmsTemplate.convertAndSend(session.getTopic(queueOwner, inventoryQueueName), jsonString);
		logger.info("Sending successful");
	}

	private String evaluateInventory(AQjmsSession session, String id) throws JMSException, SQLException {
		dbConnection = session.getDBConnection();
		logger.info("-------------->evaluateInventory connection:" + dbConnection +
				" session:" + session + " check inventory for inventoryid:" + id);
		try (OraclePreparedStatement st = (OraclePreparedStatement) dbConnection.prepareStatement(DECREMENT_BY_ID)) {
			st.setString(1, id);
			st.registerReturnParameter(2, Types.VARCHAR);
			int i = st.executeUpdate();
			ResultSet res = st.getReturnResultSet();
			if (i > 0 && res.next()) {
				String location = res.getString(1);
				logger.info("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} location {" + location + "}");
				return location;
			} else {
				logger.info("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} inventorydoesnotexist");
				return INVENTORYDOESNOTEXIST;
			}
		}
	}
}
