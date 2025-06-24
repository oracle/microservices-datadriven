package com.example;

import java.util.Date;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Access;
import jakarta.persistence.AccessType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.NamedQueries;
import jakarta.persistence.NamedQuery;
import jakarta.persistence.Table;

@Entity
@Table(name = "CUSTOMER")
@Access(AccessType.PROPERTY)
@NamedQueries({
    @NamedQuery(name = "getCustomers",
                query = "select c from Customer c"),
    @NamedQuery(name = "getCustomerById",
                query = "select c from Customer c where c.customerId = :id"),
    @NamedQuery(name = "getCustomerByCustomerNameContaining",
                query = "select c from Customer c where c.customerName like '%'||:name||'%'"),
    @NamedQuery(name = "getCustomerByCustomerEmailContaining",
                query = "select c from Customer c where c.customerEmail like '%'||:email||'%'")
})
public class Customer {
    
    private String customerId;
    private String customerName;
    private String customerEmail;
    private Date dateBecameCustomer;
    private String customerOtherDetails;
    private String customerPassword;

    public Customer() {}

    /**
     * Creates a  Customers object.
     * @param customerId The Customer ID
     * @param customerName The Customer Name
     * @param customerEmail The Customer Email
     * @param customerOtherDetails Other details about the customer
     */
    public Customer(String customerId, String customerName, String customerEmail, String customerOtherDetails) {
        this.customerId = customerId;
        this.customerName = customerName;
        this.customerEmail = customerEmail;
        this.customerOtherDetails = customerOtherDetails;
    }

    @Id
    @Column(name = "CUSTOMER_ID", nullable = false, updatable = false)
    public String getCustomerId() {
        return customerId;
    }

    public void setCustomerId(String customerId) {
        this.customerId = customerId;
    }

    @Column(name = "CUSTOMER_NAME")
    public String getCustomerName() {
        return customerName;
    }

    public void setCustomerName(String customerName) {
        this.customerName = customerName;
    }

    @Column(name = "CUSTOMER_EMAIL")
    public String getCustomerEmail() {
        return customerEmail;
    }

    public void setCustomerEmail(String customerEmail) {
        this.customerEmail = customerEmail;
    }

    @CreationTimestamp
    @Column(name = "DATE_BECAME_CUSTOMER", updatable = false, insertable = false)
    public Date getDateBecameCustomer() {
        return dateBecameCustomer;
    }

    public void setDateBecameCustomer(Date dateBecameCustomer) {
        this.dateBecameCustomer = dateBecameCustomer;
    }

    @Column(name = "CUSTOMER_OTHER_DETAILS")
    public String getCustomerOtherDetails() {
        return customerOtherDetails;
    }

    public void setCustomerOtherDetails(String customerOtherDetails) {
        this.customerOtherDetails = customerOtherDetails;
    }

    @Column(name = "PASSWORD")
    public String getCustomerPassword() {
        return customerPassword;
    }

    public void setCustomerPassword(String customerPassword) {
        this.customerPassword = customerPassword;
    }

}
