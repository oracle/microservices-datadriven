package org.example.oracle_cqrs.query.repositories;

import org.example.oracle_cqrs.query.entities.Account;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AccountRepository extends JpaRepository<Account, String> {
}
