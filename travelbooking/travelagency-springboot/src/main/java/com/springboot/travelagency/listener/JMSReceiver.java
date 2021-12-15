package com.springboot.travelagency.listener;

import javax.jms.JMSException;

import oracle.jdbc.internal.OraclePreparedStatement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import com.springboot.travelagency.model.Inventory;
import com.springboot.travelagency.model.Order;
import com.springboot.travelagency.service.SupplierService;
import com.springboot.travelagency.util.JsonUtils;

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
	
    String travelagencyQueueName = System.getenv("db_travelagencyQueueName"); // environment.getProperty("db_travelagencyQueueName");

	private Connection dbConnection;
	private static final String DECREMENT_BY_ID =
			"update travelagency set travelagencycount = travelagencycount - 1 where travelagencyid = ? and travelagencycount > 0 returning travelagencylocation into ?";
	public static final String INVENTORYDOESNOTEXIST = "travelagencydoesnotexist";
	Logger logger = LoggerFactory.getLogger(JMSReceiver.class);

	@JmsListener(destination ="ORDERQUEUE", containerFactory = "queueConnectionFactory")
	public void listenOrderEvent(String message, AQjmsSession session) throws Exception {
		logger.info("Received Message Session: " + session + " travelagencyMessage :" + message);
		Order travelagency = JsonUtils.read(message, Order.class);
		String location = evaluateInventory(session, travelagency.getItemid());
		logger.info("travelagency :" + travelagency + " location:" + location);
		travelagencyEvent(travelagency.getOrderid(), travelagency.getItemid(), location, session);
	}

	public void travelagencyEvent(String travelagencyid, String itemid, String travelagencylocation, AQjmsSession session) throws JMSException {
		Inventory travelagency = new Inventory(travelagencyid, itemid, travelagencylocation, "beer");
		String jsonString = JsonUtils.writeValueAsString(travelagency);
		logger.info("Sending reply for travelagencyId :" + travelagencyid + " itemid:" + itemid + " travelagencylocation:" + travelagencylocation+ " jsonString:" + jsonString+ " travelagencyQueueName:" + travelagencyQueueName);
		jmsTemplate.convertAndSend(session.getTopic("INVENTORYUSER", travelagencyQueueName), jsonString);
		logger.info("Sending successful");
	}

	private String evaluateInventory(AQjmsSession session, String id) throws JMSException, SQLException {
		dbConnection = session.getDBConnection();
		logger.info("-------------->evaluateInventory connection:" + dbConnection +
				" session:" + session + " check travelagency for travelagencyid:" + id);
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
				logger.info("InventoryServiceOrderEventConsumer.updateDataAndSendEventOnInventory id {" + id + "} travelagencydoesnotexist");
				return INVENTORYDOESNOTEXIST;
			}
		}
	}
}
