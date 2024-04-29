package com.example.queuereader.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Data
@ToString
@NoArgsConstructor
@AllArgsConstructor
public class TollData {

    private String accountNumber;
    private String licensePlate;
    private String carType;
    private String tagId;
    private String timeStamp;

}
