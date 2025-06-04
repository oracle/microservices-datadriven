package org.example.oracle.cqrs.command.producers;

import org.example.oracle.cqrs.common.events.BaseEvent;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

@Component
public class EventProducer {
    private final JmsTemplate jmsTemplate;
    private final String queueName;

    public EventProducer(JmsTemplate jmsTemplate, @Value("${txeventq.queue.events.name}") String queueName) {
        this.jmsTemplate = jmsTemplate;
        this.queueName = queueName;
    }

    public void enqueue(BaseEvent event) {
        jmsTemplate.convertAndSend(queueName, event);
    }
}
