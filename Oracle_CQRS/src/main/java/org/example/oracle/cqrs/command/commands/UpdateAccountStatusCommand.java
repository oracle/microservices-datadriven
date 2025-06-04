package org.example.oracle.cqrs.command.commands;

import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.oracle.cqrs.common.enums.AccountStatus;

@Getter
@NoArgsConstructor
public class UpdateAccountStatusCommand extends BaseCommand<String> {
    private String accountId;
    private AccountStatus accountStatus;

    public UpdateAccountStatusCommand(String id, String accountId, AccountStatus accountStatus) {
        super(id);
        this.accountId = accountId;
        this.accountStatus = accountStatus;
    }
}
