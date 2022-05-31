package com.cloudbank.authservice.controllers;

public class TransferResponse {

    public TransferResponse(String outcome) {
        this.outcome = outcome;
    }

    public String getOutcome() {
        return outcome;
    }

    public void setOutcome(String outcome) {
        this.outcome = outcome;
    }

    private String outcome;
}
