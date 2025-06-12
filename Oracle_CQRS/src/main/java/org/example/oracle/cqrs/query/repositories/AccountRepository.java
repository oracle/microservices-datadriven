package org.example.oracle.cqrs.query.repositories;

import org.example.oracle.cqrs.query.entities.Account;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AccountRepository extends JpaRepository<Account, String> {}
