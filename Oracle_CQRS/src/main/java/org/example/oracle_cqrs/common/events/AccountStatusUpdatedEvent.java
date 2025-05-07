package org.example.oracle_cqrs.common.events;

import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.example.oracle_cqrs.common.enums.AccountStatus;

@NoArgsConstructor
@Entity
public class AccountStatusUpdatedEvent extends BaseEvent {
    @Getter
    private AccountStatus fromStatus;
    @Getter
    private AccountStatus toStatus;
    public AccountStatusUpdatedEvent(String id, AccountStatus fromStatus, AccountStatus toStatus) {
        super(id);
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
    }
}