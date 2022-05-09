package com.cloudbank.springboot.accounts;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@CrossOrigin("http://localhost:3000")
@RequestMapping("/api/account")
public class AccountController {

    @Autowired
    private AccountService accountService;

    @GetMapping
    public List<Object> handleGetAccounts() {
        return accountService.getUserAccounts();

    }

    @GetMapping("/transfer")
    public Map<String, Object> handleTransfer() {
        return accountService.getUserAndExternalAccounts();

    }

}
