// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.accounts.repository;

import com.example.accounts.model.Journal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JournalRepository extends JpaRepository<Journal, Long> {
    Journal findJournalByLraIdAndJournalType(String lraId, String journalType);
    List<Journal> findByAccountId(long accountId);
}