package org.example.oracle_cqrs.command.aggregates;

import jakarta.transaction.Transactional;
import lombok.*;

import org.example.oracle_cqrs.command.commands.*;
import org.example.oracle_cqrs.command.producers.EventProducer;
import org.example.oracle_cqrs.command.repository.EventStoreRepository;
import org.example.oracle_cqrs.common.enums.AccountStatus;
import org.example.oracle_cqrs.common.events.AccountCreatedEvent;
import org.example.oracle_cqrs.common.events.AccountDebitedEvent;
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

        if (command instanceof CreateAccountCommand) {

            System.out.println("Handling create: " + command);
            CreateAccountCommand createAccountCommand = (CreateAccountCommand) command;
            if (createAccountCommand.getInitialBalance() < 0)
                throw new IllegalArgumentException("Initial balance is negative");

            AccountCreatedEvent event = new AccountCreatedEvent(UUID.randomUUID().toString()
                    , createAccountCommand.getInitialBalance(),
                    createAccountCommand.getCurrency(),
                    AccountStatus.CREATED);

            eventProducer.enqueue(event);
            eventStoreRepository.save(event);


        } else if (command instanceof DebitAccountCommand) {

            System.out.println("Handling debit: " + command);
            DebitAccountCommand debitAccountCommand = (DebitAccountCommand) command;
            if (debitAccountCommand.getAmount() < 0)
                throw new IllegalArgumentException("Amount is negative");

            AccountDebitedEvent event = new AccountDebitedEvent(UUID.randomUUID().toString(),
                    debitAccountCommand.getAccountId()
                    , debitAccountCommand.getCurrency(),
                    debitAccountCommand.getAmount());

            eventProducer.enqueue(event);
            eventStoreRepository.save(event);

        } else if (command instanceof CreditAccountCommand) {
            System.out.println("Handling Credit: " + command);

        } else if (command instanceof UpdateAccountStatusCommand) {
            System.out.println("Handling UpdateStatus: " + command);
        }

    }
}
