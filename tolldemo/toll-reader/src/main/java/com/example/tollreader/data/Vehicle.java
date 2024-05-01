package com.example.tollreader.data;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Vehicle {
    private @Id String vehicleId;
    private String customerId;
    private String tagId;
    private String state;
    private String licensePlate;
    private String vehicleType;
    @Column(name = "IMAGE")
    private String photoFilename;
}
