// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.journalapp.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "JOURNAL")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Journal {

    @Id
    @Column(name = "JOURNAL_ID")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer journalId;
    @Column(name = "ACCOUNT_NUMBER")
    private String accountNumber;
    @Column(name = "TAG_ID")
    private String tagId;
    @Column(name = "LICENSE_PLATE")
    private String licensePlate;
    @Column(name = "VEHICLE_TYPE")
    private String vehicleType;
    @Column(name = "TOLL_DATE")
    private String tollDate;
    @Column(name = "TOLL_COST")
    private Integer tollCost;
    @Column(name = "DETECTED_VEHICLE_TYPE")
    private String detectedVehicleType;

}
