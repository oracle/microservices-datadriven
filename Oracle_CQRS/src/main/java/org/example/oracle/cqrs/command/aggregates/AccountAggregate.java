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

        BaseEvent event;

        switch (command) {
            case CreateAccountCommand createAccountCommand -> {
                System.out.println("Handling create: " + command);
                if (createAccountCommand.getInitialBalance() < 0)
                    throw new IllegalArgumentException("Initial balance is negative");

                event = new AccountCreatedEvent(UUID.randomUUID().toString(), createAccountCommand.getInitialBalance(), createAccountCommand.getCurrency(), AccountStatus.CREATED, createAccountCommand.getAccountId());

            }
            case DebitAccountCommand debitAccountCommand -> {
                System.out.println("Handling debit: " + command);
                if (debitAccountCommand.getAmount() < 0) throw new IllegalArgumentException("Amount is negative");

                event = new AccountDebitedEvent(UUID.randomUUID().toString(), debitAccountCommand.getAccountId(), debitAccountCommand.getCurrency(), debitAccountCommand.getAmount());


            }
            case CreditAccountCommand creditAccountCommand -> {
                System.out.println("Handling debit: " + command);
                if (creditAccountCommand.getAmount() < 0) throw new IllegalArgumentException("Amount is negative");

                event = new AccountCreditedEvent(UUID.randomUUID().toString(), creditAccountCommand.getCurrency(), creditAccountCommand.getAmount(), creditAccountCommand.getAccountId());


            }
            case UpdateAccountStatusCommand updateAccountStatusCommand -> {
                System.out.println("Handling debit: " + command);
                event = new AccountStatusUpdatedEvent(UUID.randomUUID().toString(), updateAccountStatusCommand.getAccountStatus(), updateAccountStatusCommand.getAccountId());

            }

            default -> throw new IllegalStateException("Unexpected value: " + command);
        }

        eventProducer.enqueue(event);
        eventStoreRepository.save(event);

    }
}
