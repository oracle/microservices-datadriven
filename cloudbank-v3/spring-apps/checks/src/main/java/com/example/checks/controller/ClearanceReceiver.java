package com.example.checks.controller;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Component;

import com.example.checks.service.AccountService;
import com.example.testrunner.model.Clearance;

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