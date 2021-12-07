package io.micronaut.data.examples;

import io.micronaut.jms.annotations.JMSProducer;
import io.micronaut.jms.annotations.Queue;
import io.micronaut.messaging.annotation.MessageBody;

@JMSProducer("aqConnectionFactory")
public interface InventoryEventProducer {
    @Queue("inventoryuser.INVENTORYQUEUE")
    void send(@MessageBody String body);
}