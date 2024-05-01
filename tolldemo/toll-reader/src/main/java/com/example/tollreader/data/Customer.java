package com.example.tollreader.data;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Customer {
    private @Id String customerId;
    private String accountNumber;
    private String firstName;
    private String lastName;
    private String address;
    private String city;
    private String zipcode;
};

