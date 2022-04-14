package com.cloudbank.springboot.accounts.dto;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name = "CB_BANK_ACCOUNTS")
public class AccountDTO {

    @Id
    @Column(name = "ACCOUNT_ID")
    private String accountId;

    @Column(name = "ACCOUNT_NAME")
    private String accountName;

    @Column(name = "ACCOUNT_BALANCE")
    private Double accountBalance;

    protected AccountDTO() {}

    public AccountDTO(String accountId, String accountName) {
        this.accountId = accountId;
        this.accountName = accountName;
    }

    public AccountDTO(String accountId, String accountName, double accountBalance) {
        this.accountId = accountId;
        this.accountName = accountName;
        this.accountBalance = accountBalance;
    }

    public String getAccountId() {
        return accountId;
    }

    public String getAccountName() {
        return accountName;
    }

    public Double getAccountBalance() {
        return accountBalance;
    }

    public void setAccountBalance(Double accountBalance) {
        this.accountBalance = accountBalance;
    }

    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    public void setAccountName(String accountName) {
        this.accountName = accountName;
    }
}
