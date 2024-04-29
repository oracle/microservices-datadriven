package com.example.journalapp.model;

public record JournalJDBC(String journalId, String tagId, String licensePlate, String vehicleType, String tollDate) {
}

//
//create table if not exists journal (
//        journal_id varchar2(128) not null,
//tag_id varchar2(64),
//license_plate varchar2(10),
//vehicle_type varchar2(10),
//toll_date date
//);