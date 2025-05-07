package org.example.oracle_cqrs.common.events;

import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Entity
public class AccountCreditedEvent extends BaseEvent {
    @Getter
    private String currency;
    @Getter private double amount;
    public AccountCreditedEvent(String id, String currency, double amount) {
        super(id);
        this.currency = currency;
        this.amount = amount;
    }
}