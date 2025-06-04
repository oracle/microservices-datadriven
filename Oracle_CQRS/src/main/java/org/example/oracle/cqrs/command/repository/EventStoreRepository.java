package org.example.oracle.cqrs.command.repository;

import org.example.oracle.cqrs.common.events.BaseEvent;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EventStoreRepository extends JpaRepository<BaseEvent, String> {
}
