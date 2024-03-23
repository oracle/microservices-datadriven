// Copyright (c) 2023, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.accounts.model;

import java.util.Date;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Generated;
import org.hibernate.annotations.GenerationTime;

@SuppressWarnings("deprecation") // TODO: Needs to be removed
@Data
@NoArgsConstructor
@Entity
@Table(name = "ACCOUNTS")
public class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ACCOUNT_ID")
    private long accountId;
    
    @Column(name = "ACCOUNT_NAME")
    private String accountName;
    
    @Column(name = "ACCOUNT_TYPE")
    private String accountType;
    
    @Column(name = "CUSTOMER_ID")
    private String accountCustomerId;
    
    @Generated(GenerationTime.INSERT)
    @Column(name = "ACCOUNT_OPENED_DATE", updatable = false, insertable = false)
    private Date accountOpenedDate;
    
    @Column(name = "ACCOUNT_OTHER_DETAILS")
    private String accountOtherDetails;
    
    @Column(name = "ACCOUNT_BALANCE")
    private long accountBalance;

    /**
     * Create Account object.
     * @param accountName Account name
     * @param accountType Account Type
     * @param accountOtherDetails Other details about account
     * @param accountCustomerId Account Customer ID
     */
    public Account(String accountName, String accountType, String accountOtherDetails, String accountCustomerId) {
        this.accountName = accountName;
        this.accountType = accountType;
        this.accountOtherDetails = accountOtherDetails;
        this.accountCustomerId = accountCustomerId;
    }
}