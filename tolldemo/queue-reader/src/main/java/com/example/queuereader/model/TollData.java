package com.example.queuereader.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class TollData {
    private String accountNumber;
    private String licensePlate;
    private String carType;
    private String timeStamp;
}
