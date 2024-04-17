package com.example.tollreader;

public enum CarType {
    SUV("SUV"),
    PICKUP("PICKUP"),
    HATCHBACK("HATCHBACK"),
    OTHER("OTHER");

    private String carType;

    private CarType(String carType) {
        this.carType = carType;
    }

    public String getStatusCode() {
        return this.carType;
    }

}
