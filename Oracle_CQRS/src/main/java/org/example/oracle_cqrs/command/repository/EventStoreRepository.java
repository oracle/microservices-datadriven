package org.example.oracle_cqrs.command.repository;

import org.example.oracle_cqrs.common.events.BaseEvent;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EventStoreRepository extends JpaRepository<BaseEvent, String> {
}
