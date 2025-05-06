package org.example.oracle_cqrs.command.commands;

import lombok.*;

@Getter @NoArgsConstructor
public class CreateAccountCommand extends BaseCommand<String> {
    private double initialBalance;
    private String currency;

    public CreateAccountCommand(String id,  double initialBalance, String currency) {
        super(id);
        this.initialBalance = initialBalance;
        this.currency = currency;
    }
}
