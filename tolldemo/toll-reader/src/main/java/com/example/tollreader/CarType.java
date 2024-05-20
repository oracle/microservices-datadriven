// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

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
