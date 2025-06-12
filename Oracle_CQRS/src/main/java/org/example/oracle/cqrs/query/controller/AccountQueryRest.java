package org.example.oracle.cqrs.query.controller;


import org.example.oracle.cqrs.query.entities.Account;
import org.example.oracle.cqrs.query.repositories.AccountRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/queries")
public class AccountQueryRest {

    private AccountRepository accountRepository;

    public AccountQueryRest(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    @GetMapping("allAccounts")
    public List<Account> getAccounts() {
        return accountRepository.findAll();
    }

    @GetMapping("/{accountId}")
    public ResponseEntity<Account> getAccount(@PathVariable String accountId) {
        return accountRepository.findById(accountId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("status/{accountId}")
    public ResponseEntity<String> getAccountStatus(@PathVariable String accountId) {
        return accountRepository.findById(accountId)
                .map(account -> ResponseEntity.ok(account.getStatus().toString()))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

}
