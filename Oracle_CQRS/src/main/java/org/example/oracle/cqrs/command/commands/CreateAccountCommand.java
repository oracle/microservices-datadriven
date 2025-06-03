package org.example.oracle.cqrs.command.commands;

import lombok.*;

@Getter @NoArgsConstructor
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
}
