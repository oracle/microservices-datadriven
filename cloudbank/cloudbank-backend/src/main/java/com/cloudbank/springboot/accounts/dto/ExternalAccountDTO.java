package com.cloudbank.springboot.accounts.dto;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;

@Entity
@Table(name = "CB_EXTERNAL_ACCOUNTS")
public class ExternalAccountDTO {

    @Id
    @Column(name = "RECORD_ID")
    private long id;

    @Column(name = "ACCOUNT_ID")
    private String accountId;

    @Column(name = "ACCOUNT_NAME")
    private String accountName;

    @Column(name = "ACTIVATED")
    private int activated;

    protected ExternalAccountDTO() {}

    public ExternalAccountDTO(long id, String accountId, String accountName) {
        this.id = id;
        this.accountId = accountId;
        this.accountName = accountName;
    }

    public long getId() {
        return id;
    }

    public String getAccountId() {
        return accountId;
    }

    public String getAccountName() {
        return accountName;
    }

    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    public void setAccountName(String accountName) {
        this.accountName = accountName;
    }

    public void setId(long id) {
        this.id = id;
    }

    public int getActivated() {
        return activated;
    }

    public void setActivated(int activated) {
        this.activated = activated;
    }
}
