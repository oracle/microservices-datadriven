package io.micronaut.data.examples;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micronaut.jms.annotations.JMSListener;
import io.micronaut.jms.annotations.Queue;
import io.micronaut.messaging.annotation.MessageBody;

//@JMSListener("aqConnectionFactory")
public class InventoryOrderEventConsumer {

    @Queue(value = "inventoryuser.ORDERQUEUE", concurrency = "1-5")
    public void receive(@MessageBody String body) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        Order order = mapper.readValue(body, Order.class);
        System.out.println("InventoryOrderEventConsumer.receive order:" + order);
    }
}
