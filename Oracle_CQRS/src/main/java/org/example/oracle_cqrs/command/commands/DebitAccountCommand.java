package org.example.oracle_cqrs.command.commands;

import lombok.*;

@Getter @NoArgsConstructor
public class DebitAccountCommand extends BaseCommand<String> {
    private String accountId;
    private double amount;
    private String currency;

    public DebitAccountCommand(String id, String accountId, double amount, String currency) {
        super(id);
        this.accountId = accountId;
        this.amount = amount;
        this.currency = currency;
    }

}
