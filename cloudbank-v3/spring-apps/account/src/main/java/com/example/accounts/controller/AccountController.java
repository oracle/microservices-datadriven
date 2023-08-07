// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.accounts.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.example.accounts.repository.AccountRepository;
import com.example.accounts.repository.JournalRepository;
import java.util.List;
import com.example.accounts.model.Account;
import com.example.accounts.model.Journal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import java.util.ArrayList;
import java.util.Optional;
import org.springframework.web.bind.annotation.DeleteMapping;

@RestController
@RequestMapping("/api/v1")
public class AccountController {

    final AccountRepository accountRepository;
    final JournalRepository journalRepository;

    public AccountController(AccountRepository accountRepository, JournalRepository journalRepository) {
        this.accountRepository = accountRepository;
        this.journalRepository = journalRepository;
    }

    @GetMapping("/accounts")
    public List<Account> getAllAccounts() {
        return accountRepository.findAll();
    }

    @PostMapping("/account")
    public ResponseEntity<Account> createAccount(@RequestBody Account account) {
        try {
            Account _account = accountRepository.saveAndFlush(account);
            return new ResponseEntity<>(_account, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/account/{accountId}")
    public ResponseEntity<Account> getAccountById(@PathVariable("accountId") long accountId) {
        Optional<Account> accountData = accountRepository.findById(accountId);
        try {
            return accountData.map(account -> new ResponseEntity<>(account, HttpStatus.OK))
                    .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/account/getAccounts/{customerId}")
    public ResponseEntity<List<Account>> getAccountsByCustomerId(@PathVariable("customerId") String customerId) {
        try {
            List<Account> accountData = new ArrayList<Account>();
            accountData.addAll(accountRepository.findByAccountCustomerId(customerId));
            if (accountData.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return new ResponseEntity<>(accountData, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @DeleteMapping("/account/{accountId}")
    public ResponseEntity<HttpStatus> deleteAccount(@PathVariable("accountId") long accountId) {
        try {
            accountRepository.deleteById(accountId);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/account/{accountId}/transactions")
    public ResponseEntity<List<Journal>> getTransactions(@PathVariable("accountId") long accountId) {
        try {
            List<Journal> transactions = new ArrayList<Journal>();
            transactions.addAll(journalRepository.findByAccountId(accountId));
            if (transactions.isEmpty()) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            }
            return new ResponseEntity<>(transactions, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/account/journal")
    public ResponseEntity<Journal> postSimpleJournalEntry(@RequestBody Journal journalEntry) {
        try {
            Journal _journalEntry = journalRepository.saveAndFlush(journalEntry);
            return new ResponseEntity<>(_journalEntry, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @GetMapping("/account/{accountId}/journal")
    public List<Journal> getJournalEntriesForAccount(@PathVariable("accountId") long accountId) {
        return journalRepository.findJournalByAccountId(accountId);
    }

    @PostMapping("/account/journal/{journalId}/clear")
    public ResponseEntity<Journal> clearJournalEntry(@PathVariable long journalId) {
        try {
            Optional<Journal> data = journalRepository.findById(journalId);
            if (data.isPresent()) {
                Journal _journalEntry = data.get();
                _journalEntry.setJournalType("DEPOSIT");
                journalRepository.saveAndFlush(_journalEntry);
                return new ResponseEntity<Journal>(_journalEntry, HttpStatus.OK);
            } else {
                return new ResponseEntity<Journal>(new Journal(), HttpStatus.ACCEPTED);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

}