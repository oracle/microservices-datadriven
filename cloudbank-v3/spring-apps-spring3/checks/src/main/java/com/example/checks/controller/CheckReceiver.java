package com.example.checks.controller;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

import com.example.checks.clients.Journal;
import com.example.checks.service.AccountService;
import com.example.testrunner.model.CheckDeposit;

@Component
public class CheckReceiver {

    private AccountService accountService;

    public CheckReceiver(AccountService accountService) {
        this.accountService = accountService;
    }

    @JmsListener(destination = "deposits", containerFactory = "factory")
    public void receiveMessage(CheckDeposit deposit) {
        System.out.println("Received deposit <" + deposit + ">");
        accountService.journal(new Journal("PENDING", deposit.getAccountId(), deposit.getAmount()));
    }

}