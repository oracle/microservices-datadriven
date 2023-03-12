// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.accounts.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.accounts.model.Account;

public interface AccountRepository extends JpaRepository<Account, Long> {   
    List<Account> findByAccountCustomerId(String customerId); 
    List<Account> findAccountsByAccountNameContains (String accountName);
    Account findByAccountId(long accountId);
}