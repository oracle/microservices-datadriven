package org.example.oracle.cqrs.common.events;

import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.oracle.cqrs.common.enums.AccountStatus;

@NoArgsConstructor
@Entity
@Getter
public class AccountStatusUpdatedEvent extends BaseEvent {
    private AccountStatus newStatus;
    private String accountId;

    public AccountStatusUpdatedEvent(String id, AccountStatus newStatus, String accountId) {
        super(id);
        this.newStatus = newStatus;
        this.accountId = accountId;
    }
}