// Copyright (c) 2024, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/

package com.example.tollreader;

public enum State {
  AL("Alabama"),
  MT("Montana"),
  AK("Alaska"),
  NE("Nebraska"),
  AZ("Arizona"),
  NV("Nevada"),
  AR("Arkansas"),
  NH("NewHampshire"),
  CA("California"),
  NJ("NewJersey"),
  CO("Colorado"),
  NM("NewMexico"),
  CT("Connecticut"),
  NY("NewYork"),
  DE("Delaware"),
  NC("NorthCarolina"),
  FL("Florida"),
  ND("NorthDakota"),
  GA("Georgia"),
  OH("Ohio"),
  HI("Hawaii"),
  OK("Oklahoma"),
  ID("Idaho"),
  OR("Oregon"),
  IL("Illinois"),
  PA("Pennsylvania"),
  IN("Indiana"),
  RI("RhodeIsland"),
  IA("Iowa"),
  SC("SouthCarolina"),
  KS("Kansas"),
  SD("SouthDakota"),
  KY("Kentucky"),
  TN("Tennessee"),
  LA("Louisiana"),
  TX("Texas"),
  ME("Maine"),
  UT("Utah"),
  MD("Maryland"),
  VT("Vermont"),
  MA("Massachusetts"),
  VA("Virginia"),
  MI("Michigan"),
  WA("Washington"),
  MN("Minnesota"),
  WV("WestVirginia"),
  MS("Mississippi"),
  WI("Wisconsin"),
  MO("Missouri"),
  WY("Wyoming");

  private final String state;

  private State(String state) {
    this.state = state;
  }

  public String getStatusCode() {
    return this.state;
  }
}