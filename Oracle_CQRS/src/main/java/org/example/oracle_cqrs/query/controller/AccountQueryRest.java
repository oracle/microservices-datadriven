package org.example.oracle_cqrs.query.controller;


import org.example.oracle_cqrs.query.entities.Account;
import org.example.oracle_cqrs.query.repositories.AccountRepository;
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
    public List<Account> getAccounts(){
        return accountRepository.findAll() ;
    }

    @GetMapping("/{accountId}")
    public Account getAccount(@PathVariable String accountId){
        return accountRepository.findById(accountId).orElse(null);
    }

}
