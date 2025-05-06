package org.example.oracle_cqrs.command.commands;


import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter @NoArgsConstructor
public class CreditAccountCommand extends BaseCommand<String> {
    private String accountId ;
    private double amount;

    public CreditAccountCommand(String id, String accountId, double amount) {
        super(id);
        this.accountId = accountId;
        this.amount = amount;
    }
}
