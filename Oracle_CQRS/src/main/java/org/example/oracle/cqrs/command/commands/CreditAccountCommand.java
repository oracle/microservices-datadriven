package org.example.oracle.cqrs.command.commands;


import lombok.Getter;
import lombok.NoArgsConstructor;

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
}
