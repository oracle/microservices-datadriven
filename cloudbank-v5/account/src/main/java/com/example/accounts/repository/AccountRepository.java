// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.accounts.repository;

import java.util.List;

import com.example.accounts.model.Account;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;

public interface AccountRepository extends JpaRepository<Account, Long> {

    List<Account> findByAccountCustomerId(String customerId);

    List<Account> findAccountsByAccountNameContains(String accountName);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    Account findByAccountId(long accountId);
}
