package org.example.oracle.cqrs.command.commands;

import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.oracle.cqrs.common.enums.AccountStatus;
import org.example.oracle.cqrs.common.events.AccountCreatedEvent;
import org.example.oracle.cqrs.common.events.BaseEvent;

import java.util.UUID;

@Getter
@NoArgsConstructor
public class CreateAccountCommand extends BaseCommand<String> {
    private double initialBalance;
    private String currency;
    private String accountId ;

    public CreateAccountCommand(String id, double initialBalance, String currency, String accountId) {
        super(id);
        this.initialBalance = initialBalance;
        this.currency = currency;
        this.accountId = accountId;
    }

    @Override
    public BaseEvent createEvent() {
        System.out.println("Handling create: " + this);
        if (this.getInitialBalance() < 0)
            throw new IllegalArgumentException("Initial balance is negative");

        return new AccountCreatedEvent(UUID.randomUUID().toString(), initialBalance, currency, AccountStatus.CREATED, accountId);
    }
}
