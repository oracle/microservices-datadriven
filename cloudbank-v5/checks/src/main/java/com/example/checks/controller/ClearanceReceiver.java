// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.checks.controller;

import com.example.checks.service.AccountService;
import com.example.testrunner.model.Clearance;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

@Component
public class ClearanceReceiver {

    private AccountService accountService;

    public ClearanceReceiver(AccountService accountService) {
        this.accountService = accountService;
    }

    @JmsListener(destination = "clearances", containerFactory = "factory")
    public void receiveMessage(Clearance clearance) {
        System.out.println("Received clearance <" + clearance + ">");
        accountService.clear(clearance);
    }

}