// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

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

    /**
     * Create Journal object.
     * @param journalType Journal Type
     * @param accountId Account Id
     * @param journalAmount Amount
     */
    public Journal(String journalType, long accountId, long journalAmount) {
        this.journalType = journalType;
        this.accountId = accountId;
        this.journalAmount = journalAmount;
        this.lraId = "0";
        this.lraState = "";
    }
}