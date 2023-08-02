package com.example.checks.clients;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Journal {
    private long journalId;
    private String journalType;
    private long accountId;
    private String lraId;
    private String lraState;
    private long journalAmount;

    public Journal(String journalType, long accountId, long journalAmount) {
        this.journalType = journalType;
        this.accountId = accountId;
        this.journalAmount = journalAmount;
        this.lraId = "0";
        this.lraState = "";
    }
}