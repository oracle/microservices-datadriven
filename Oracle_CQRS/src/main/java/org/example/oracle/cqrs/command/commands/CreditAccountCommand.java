package org.example.oracle.cqrs.command.commands;


import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.oracle.cqrs.common.events.AccountCreditedEvent;
import org.example.oracle.cqrs.common.events.BaseEvent;

import java.util.UUID;

@Getter
@NoArgsConstructor
public class CreditAccountCommand extends BaseCommand<String> {
    private String accountId;
    private double amount;
    private String currency;

    public CreditAccountCommand(String id, String accountId, double amount, String currency) {
        super(id);
        this.accountId = accountId;
        this.amount = amount;
        this.currency = currency;
    }

    @Override
    public BaseEvent createEvent() {
        System.out.println("Handling debit: " + this);
        if (amount < 0) throw new IllegalArgumentException("Amount is negative");

        return new AccountCreditedEvent(UUID.randomUUID().toString(), currency, amount, accountId);

    }
}
