package com.example.tollreader;

public enum CarType {
  SUV("SUV"),
  PICKUP("PICKUP"),
  HATCHBACK("HATCHBACK"),
  SEDAN("SEDAN"),
  OTHER("OTHER");

  private final String carType;

  private CarType(String carType) {
    this.carType = carType;
  }

  public String getStatusCode() {
    return this.carType;
  }

}
