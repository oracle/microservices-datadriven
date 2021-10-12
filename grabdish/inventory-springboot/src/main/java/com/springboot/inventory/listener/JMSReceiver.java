package com.springboot.inventory.listener;

import javax.jms.JMSException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

import com.springboot.inventory.dto.InventoryTable;
import com.springboot.inventory.model.Order;
import com.springboot.inventory.service.SupplierService;
import com.springboot.inventory.util.JsonUtils;

import oracle.jms.AQjmsSession;

@Component
public class JMSReceiver {

	@Autowired
	JmsTemplate jmsTemplate;

	@Autowired
	SupplierService supplierService;

	Logger logger = LoggerFactory.getLogger(JMSReceiver.class);

	@JmsListener(destination = "ORDER_QUEUE", containerFactory = "queueConnectionFactory")
	public void listenOrderEvent(String message, AQjmsSession session) throws JMSException {
		Order order = JsonUtils.read(message, Order.class);

		logger.info("ListenOrderEvenet orderMessage :" + message);

		String location = evaluateInventory(order, session);
		inventoryEvent(order.getOrderid(), order.getItemid(), location);

		logger.info("Received Message Session: " + session);
	}

	public void inventoryEvent(String orderId, String itemId, String location) throws JMSException {

		InventoryTable inventory = new InventoryTable(orderId, itemId, location, "beer");
		String jsonString = JsonUtils.writeValueAsString(inventory);

		jmsTemplate.convertAndSend("INVENTORY_QUEUE", jsonString);

		logger.info("Inventory template" + jsonString + "\n");
	}

	public String evaluateInventory(Order order, AQjmsSession session) {
		String itemId = order.getItemid();
		supplierService.removeInventory(itemId);
		InventoryTable viewInventory = supplierService.getInventory(itemId);
		logger.info("Evaluate Inventory Session" + session);
		String inventoryLocation = viewInventory != null ? viewInventory.getInventoryLocation()
				: "inventoryDoesNotExist";

		logger.info("Evaluate Inventory orderId:" + order.getOrderid());
		logger.info("Evaluate Inventory itemId:" + order.getItemid());
		logger.info("Evaluate Inventory Session" + session);

		return inventoryLocation;
	}

}
