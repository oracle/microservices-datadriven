package org.example.oracle.cqrs.common.events;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.oracle.cqrs.common.enums.AccountStatus;


@NoArgsConstructor
@Entity
public class AccountCreatedEvent extends BaseEvent {
    @Getter
    private double initialBalance;
    @Getter
    private String currency;
    @Enumerated(EnumType.STRING)
    @Getter
    private AccountStatus accountStatus;
    @Getter
    private String accountId;

    public AccountCreatedEvent(String id, double initialBalance, String currency, AccountStatus accountStatus, String accountId) {
        super(id);
        this.initialBalance = initialBalance;
        this.currency = currency;
        this.accountStatus = accountStatus;
        this.accountId = accountId;
    }
}