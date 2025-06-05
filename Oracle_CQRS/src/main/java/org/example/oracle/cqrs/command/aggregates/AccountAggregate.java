package org.example.oracle.cqrs.command.aggregates;

import jakarta.transaction.Transactional;
import lombok.*;

import org.example.oracle.cqrs.command.commands.*;
import org.example.oracle.cqrs.common.events.*;
import org.example.oracle.cqrs.command.producers.EventProducer;
import org.example.oracle.cqrs.command.repository.EventStoreRepository;
import org.example.oracle.cqrs.common.enums.AccountStatus;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

import java.util.UUID;


@Component
@Transactional
public class AccountAggregate {
    @Getter
    private String accountId;
    @Getter
    private double currentBalance;
    @Getter
    private String currency;
    @Getter
    private AccountStatus status;

    private EventProducer eventProducer;
    private EventStoreRepository eventStoreRepository;

    public AccountAggregate(EventProducer eventProducer, EventStoreRepository eventStoreRepository) {
        this.eventProducer = eventProducer;
        this.eventStoreRepository = eventStoreRepository;
    }


    @JmsListener(destination = "${txeventq.queue.commands.name}", id = "sampleCommand")
    void handleCommand(BaseCommand command) {
        BaseEvent event = command.createEvent();
        eventProducer.enqueue(event);
        eventStoreRepository.save(event);
    }
}
