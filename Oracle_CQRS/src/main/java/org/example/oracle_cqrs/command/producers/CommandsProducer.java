package org.example.oracle_cqrs.command.producers;

import org.example.oracle_cqrs.command.commands.BaseCommand;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;

@Component
public class CommandsProducer {
    private final JmsTemplate jmsTemplate;
    private final String queueName;

    public CommandsProducer(JmsTemplate jmsTemplate,
                            @Value("${txeventq.queue.commands.name}") String queueName) {
        this.jmsTemplate = jmsTemplate;
        this.queueName = queueName;
    }

    public void enqueue(BaseCommand command) {
        jmsTemplate.convertAndSend(queueName, command);
    }
}
