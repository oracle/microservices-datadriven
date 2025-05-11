package org.example.oracle.cqrs.query.eventHandlers;

import org.example.oracle.cqrs.common.events.*;
import org.example.oracle.cqrs.query.entities.Account;
import org.example.oracle.cqrs.query.repositories.AccountRepository;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

import java.util.Date;

@Component
public class AccountEventHandlers {

    private AccountRepository accountRepository;

    public AccountEventHandlers(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    @JmsListener(destination = "${txeventq.queue.events.name}", id = "sampleEvent")
    void handleEvent(BaseEvent event) {

        Account account;
        switch (event) {
            case AccountCreatedEvent accountCreatedEvent -> {

                System.out.println("Handling AccountCreatedEvent: " + accountCreatedEvent);

                account = Account.builder()
                        .accountId(accountCreatedEvent.getAccountId())
                        .balance(accountCreatedEvent.getInitialBalance())
                        .createdAt(new Date())
                        .currency(accountCreatedEvent.getCurrency())
                        .status(accountCreatedEvent.getAccountStatus())
                        .build();

            }

            case AccountDebitedEvent accountDebitedEvent -> {

                System.out.println("Handling AccountDebitedEvent: " + accountDebitedEvent);

                account = accountRepository.findById(accountDebitedEvent.getAccountId()).orElse(null);

                /** to do  **/
                //check the currency
                //rollback the accountDebitedEvent if amount > balance
                if (account.getBalance() < accountDebitedEvent.getAmount()) {
                    throw new RuntimeException("Insufficient Balance");
                }
                account.setBalance(account.getBalance() - accountDebitedEvent.getAmount());

            }

            case AccountCreditedEvent accountCreditedEvent -> {
                System.out.println("Handling accountCreditedEvent: " + accountCreditedEvent);
                account = accountRepository.findById(accountCreditedEvent.getAccountId()).orElse(null);
                account.setBalance(account.getBalance() + accountCreditedEvent.getAmount());
            }

            case AccountStatusUpdatedEvent accountStatusUpdatedEvent -> {
                System.out.println("Handling accountStatusUpdatedEvent: " + accountStatusUpdatedEvent);
                account = accountRepository.findById(accountStatusUpdatedEvent.getAccountId()).orElse(null);
                account.setStatus(accountStatusUpdatedEvent.getNewStatus());
            }
            default -> throw new IllegalStateException("Unexpected value: " + event);
        }

        accountRepository.save(account);

    }
}
