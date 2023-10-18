// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.checks.service;

import com.example.checks.clients.AccountClient;
import com.example.checks.clients.Journal;
import com.example.testrunner.model.Clearance;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AccountService {

    private final AccountClient accountClient;

    public void journal(Journal journal) {
        accountClient.journal(journal);
    }

    public void clear(Clearance clearance) {
        accountClient.clear(clearance.getJournalId());
    }

}