package org.example.oracle_cqrs.common.events;

import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Entity
public class AccountDebitedEvent extends BaseEvent {
    @Getter private String accountId;
    @Getter private String currency;
    @Getter private double amount;
    public AccountDebitedEvent(String id, String accountId, String currency, double amount) {
        super(id);
        this.accountId = accountId;
        this.currency = currency;
        this.amount = amount;
    }
}