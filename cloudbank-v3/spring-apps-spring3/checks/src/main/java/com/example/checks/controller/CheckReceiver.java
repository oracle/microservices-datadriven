// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.checks.controller;

import com.example.checks.clients.Journal;
import com.example.checks.service.AccountService;
import com.example.testrunner.model.CheckDeposit;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

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