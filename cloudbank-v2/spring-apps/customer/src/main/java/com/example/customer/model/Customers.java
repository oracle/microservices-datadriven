// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

package com.example.customer.model;

import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.Table;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Column;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.GenerationTime;
import org.hibernate.annotations.Generated;

import java.util.Date;

@Entity
@Table(name = "CUSTOMERS")
@Data
@NoArgsConstructor
public class Customers {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "CUSTOMER_ID")
    private String customerId;

    @Column(name = "CUSTOMER_NAME")
    private String customerName;

    @Column(name = "CUSTOMER_EMAIL")
    private String customerEmail;

    @Generated(GenerationTime.INSERT)
    @Column(name = "DATE_BECAME_CUSTOMER", updatable = false, insertable = false)
    private Date dateBecameCustomer;

    @Column(name = "CUSTOMER_OTHER_DETAILS")
    private String customerOtherDetails;

    @Column(name = "PASSWORD")
    private String customerPassword;

    public Customers(String customerId, String customerName, String customerEmail, String customerOtherDetails) {
        this.customerId = customerId;
        this.customerName = customerName;
        this.customerEmail = customerEmail;
        this.customerOtherDetails = customerOtherDetails;
    }
}
