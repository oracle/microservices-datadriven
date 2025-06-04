package org.example.oracle.cqrs.common.events;

import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Entity
@Getter
public class AccountCreditedEvent extends BaseEvent {
    private String currency;
    private double amount;
    private String accountId;

    public AccountCreditedEvent(String id, String currency, double amount, String accountId) {
        super(id);
        this.currency = currency;
        this.amount = amount;
        this.accountId = accountId;
    }
}