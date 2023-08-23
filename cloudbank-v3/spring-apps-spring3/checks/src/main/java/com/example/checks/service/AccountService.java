package com.example.checks.service;

import org.springframework.stereotype.Service;

import com.example.checks.clients.AccountClient;
import com.example.checks.clients.Journal;
import com.example.testrunner.model.Clearance;

import lombok.RequiredArgsConstructor;

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