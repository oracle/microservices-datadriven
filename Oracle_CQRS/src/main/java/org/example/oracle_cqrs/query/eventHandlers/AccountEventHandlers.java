package org.example.oracle_cqrs.query.eventHandlers;

import org.example.oracle_cqrs.common.events.*;
import org.example.oracle_cqrs.query.entities.Account;
import org.example.oracle_cqrs.query.repositories.AccountRepository;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.UUID;

@Component
public class AccountEventHandlers {

    private AccountRepository accountRepository;

    public AccountEventHandlers(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    @JmsListener(destination = "${txeventq.queue.events.name}", id = "sampleEvent")
    void handleEvent(BaseEvent event) {
        if (event instanceof AccountCreatedEvent) {

            System.out.println("Handling AccountCreatedEvent: " + event);
            AccountCreatedEvent accountCreatedEvent = (AccountCreatedEvent) event;

            Account account = Account.builder()
                    .accountId(UUID.randomUUID().toString())
                    .balance(accountCreatedEvent.getInitialBalance())
                    .createdAt(new Date())
                    .currency(accountCreatedEvent.getCurrency())
                    .status(accountCreatedEvent.getAccountStatus())
                    .build();

            accountRepository.save(account);

        } else if (event instanceof AccountDebitedEvent) {

            System.out.println("Handling AccountDebitedEvent: " + event);
            AccountDebitedEvent accountDebitedEvent = (AccountDebitedEvent) event;

            Account account = accountRepository.findById(accountDebitedEvent.getAccountId()).orElse(null);
            // check currency
            account.setBalance(account.getBalance() - accountDebitedEvent.getAmount());

            accountRepository.save(account);

        } else if (event instanceof AccountCreditedEvent) {
            System.out.println("Handling AccountCreditedEvent: " + event);


        } else if (event instanceof AccountStatusUpdatedEvent) {

            System.out.println("Handling AccountStatusUpdatedEvent: " + event);

        }
    }
}
