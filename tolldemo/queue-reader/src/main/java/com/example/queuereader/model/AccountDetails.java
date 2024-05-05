package com.example.queuereader.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccountDetails {
    private String customerId;
    private String accountNumber;
    private String firstName;
    private String lastName;
    private String address;
    private String city;
    private String zipcode;
    private String vehicleId;
    private String tagId;
    private String state;
    private String licensePlate;
    private String vehicleType;
}
